defmodule ElixirConsoleWeb.ConsoleLive.CommandInputComponent do
  @moduledoc """
  Live component module that implements the portion of the application where
  users prompt the commands. It also handles special key events to mimic the iEX
  user experience.
  """

  use Phoenix.LiveComponent
  alias ElixirConsole.Autocomplete

  @tab_keycode 9
  @up_keycode 38
  @down_keycode 40

  def render(assigns) do
    Phoenix.View.render(ElixirConsoleWeb.ConsoleView, "command_input.html", assigns)
  end

  def mount(socket) do
    {:ok,
     assign(
       socket,
       history_counter: 0,
       input_value: "",
       caret_position: 0
     )}
  end

  def handle_event("suggest", %{"keyCode" => @tab_keycode, "value" => value}, socket) do
    %{caret_position: caret_position, bindings: bindings} = socket.assigns

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

  def handle_event("suggest", %{"keyCode" => @up_keycode}, socket) do
    %{history_counter: counter, history: history} = socket.assigns
    {input_value, new_counter} = get_previous_history_entry(history, counter)

    {:noreply, assign(socket, input_value: input_value, history_counter: new_counter)}
  end

  def handle_event("suggest", %{"keyCode" => @down_keycode}, socket) do
    %{history_counter: counter, history: history} = socket.assigns
    {input_value, new_counter} = get_next_history_entry(history, counter)

    {:noreply, assign(socket, input_value: input_value, history_counter: new_counter)}
  end

  def handle_event("suggest", _key, socket) do
    {:noreply, assign(socket, history_counter: -1, input_value: "")}
  end

  def handle_event("caret-position", %{"position" => position}, socket) do
    {:noreply, assign(socket, caret_position: position)}
  end

  def handle_event("execute", %{"command" => command}, socket) do
    send(self(), {:execute_command, command})
    {:noreply, socket}
  end

  defp get_previous_history_entry([], _counter), do: {[], 0}

  defp get_previous_history_entry(history, counter) when counter + 1 < length(history) do
    {[Enum.at(history, counter + 1)], counter + 1}
  end

  defp get_previous_history_entry(history, counter) do
    {[List.last(history)], counter}
  end

  defp get_next_history_entry([], _counter), do: {[], 0}

  defp get_next_history_entry(history, counter) when counter > 0 do
    {[Enum.at(history, counter - 1)], counter - 1}
  end

  defp get_next_history_entry(history, _counter) do
    {[List.first(history)], 0}
  end
end
