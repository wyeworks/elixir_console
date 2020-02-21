defmodule ElixirConsoleWeb.ConsoleLive.CommandInputComponent do
  use Phoenix.LiveComponent

  alias ElixirConsole.{Autocomplete, Sandbox}
  alias ElixirConsoleWeb.ConsoleLive.Output
  alias ElixirConsoleWeb.LiveMonitor

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

  # TAB KEY
  def handle_event("suggest", %{"keyCode" => 9, "value" => value}, socket) do
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

  # KEY UP
  def handle_event("suggest", %{"keyCode" => 38}, socket) do
    counter = socket.assigns.history_counter
    history = socket.assigns.history

    {input_value, new_counter} =
      cond do
        history == [] ->
          {[], 0}

        counter + 1 < length(history) ->
          {[Enum.at(history, counter + 1)], counter + 1}

        counter + 1 >= length(history) ->
          {[List.last(history)], counter}
      end

    {:noreply, assign(socket, input_value: input_value, history_counter: new_counter)}
  end

  # KEY DOWN
  def handle_event("suggest", %{"keyCode" => 40}, socket) do
    counter = socket.assigns.history_counter
    history = socket.assigns.history

    {input_value, new_counter} =
      cond do
        history == [] ->
          {[], 0}

        counter > 0 ->
          {[Enum.at(history, counter - 1)], counter - 1}

        counter <= 0 ->
          {[List.first(history)], 0}
      end

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
end
