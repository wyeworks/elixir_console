defmodule ElixirConsoleWeb.ConsoleLive.CommandInputComponent do
  @moduledoc """
  Live component module that implements the portion of the application where
  users prompt the commands. It also handles special key events to mimic the iEX
  user experience.
  """

  use Phoenix.LiveComponent
  import ElixirConsoleWeb.ConsoleLive.Helpers
  alias ElixirConsole.Autocomplete

  @tab_keycode "Tab"
  @up_keycode "ArrowUp"
  @down_keycode "ArrowDown"

  def mount(socket) do
    {:ok,
     assign(
       socket,
       history_counter: 0,
       input_value: "",
       caret_position: 0
     )}
  end

  defp ensure_number(value) when is_number(value),
    do: value

  defp ensure_number(value), do: String.to_integer(value)

  def handle_event(
        "keydown",
        %{"key" => @tab_keycode, "value" => value, "caret_position" => caret_position},
        socket
      ) do
    %{bindings: bindings} = socket.assigns

    # When testing this event using render_keydown/up, even if the metadata is defined as a number,
    # we're receiving the value here as a string.
    # This happens only in tests though, when running the server we correctly receive it as a number.
    caret_position = ensure_number(caret_position)

    case Autocomplete.get_suggestions(value, caret_position, bindings) do
      [suggestion] ->
        {new_input, new_caret_position} =
          Autocomplete.autocompleted_input(value, caret_position, suggestion)

        send(self(), {:update_suggestions, []})

        {:noreply,
         assign(socket,
           input_value: new_input,
           caret_position: new_caret_position
         )}

      suggestions ->
        send(self(), {:update_suggestions, suggestions})

        {:noreply, assign(socket, input_value: "")}
    end
  end

  def handle_event("keydown", %{"key" => @up_keycode}, socket) do
    %{history_counter: counter, history: history} = socket.assigns
    {input_value, new_counter} = get_previous_history_entry(history, counter)
    new_caret_position = String.length(input_value)

    {:noreply,
     assign(socket,
       input_value: input_value,
       history_counter: new_counter,
       caret_position: new_caret_position
     )}
  end

  def handle_event("keydown", %{"key" => @down_keycode}, socket) do
    %{history_counter: counter, history: history} = socket.assigns
    {input_value, new_counter} = get_next_history_entry(history, counter)
    new_caret_position = String.length(input_value)

    {:noreply,
     assign(socket,
       input_value: input_value,
       history_counter: new_counter,
       caret_position: new_caret_position
     )}
  end

  def handle_event("keydown", _key, socket) do
    {:noreply, assign(socket, history_counter: -1, input_value: "")}
  end

  def handle_event("execute", %{"command" => command}, socket) do
    send(self(), {:execute_command, command})
    {:noreply, push_event(socket, "reset", %{})}
  end

  defp get_previous_history_entry([], _counter), do: {"", 0}

  defp get_previous_history_entry(history, counter) when counter + 1 < length(history) do
    {Enum.at(history, counter + 1), counter + 1}
  end

  defp get_previous_history_entry(history, counter) do
    {List.last(history), counter}
  end

  defp get_next_history_entry([], _counter), do: {"", 0}

  defp get_next_history_entry(history, counter) when counter > 0 do
    {Enum.at(history, counter - 1), counter - 1}
  end

  defp get_next_history_entry(history, _counter) do
    {List.first(history), 0}
  end
end
