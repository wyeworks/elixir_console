defmodule LiveViewDemoWeb.ConsoleLive do
  use Phoenix.LiveView

  @console_buffer 100

  defmodule Output do
    @enforce_keys [:command]
    defstruct [:command, :result, :error]
  end

  def render(assigns) do
    ~L"""
    <div class="flex h-full flex-col sm:flex-row">
      <div class="flex-1 sm:h-full overflow-scroll">
        <form phx-submit="execute" class="h-full flex flex-col">
          <div class="flex-1"></div>
          <div class="p-2">
            <%= for output <- @output do %>
              <div class="text-gray-300 font-medium"><%= print_prompt() %>
                <%= for part <- splitted_command(output.command) do %>
                  <%= case part do
                    {part, docs} ->
                      render_command_inline_help(assigns, part, docs)
                    part ->
                      part
                  end %>
                <% end %>
              </div>
              <div class="text-teal-300">
                <%= if output.result do output.result end %>
                <%= if output.error do %><span class="text-pink-400"><%= output.error %></span><% end %>
              </div>
            <% end %>
          </div>
          <div class="text-gray-300 font-medium flex bg-teal-700 p-2">
            <%= print_prompt() %>
            <input
              type="text"
              id="commandInput"
              class="ml-2 bg-transparent flex-1 outline-none"
              autocomplete="off"
              name="command"
              phx-keydown="suggest"
              phx-hook="CommandInput"
              data-input_value="<%= @input_value %>"
            />
          </div>
        </form>
      </div>
      <div class="w-full sm:w-32 md:w-64 h-32 sm:h-full bg-teal-800 p-2 text-gray-300 overflow-scroll flex flex-col">
        <h2 class="font-medium">Current Variables</h2>
        <ul>
          <%= for {key, value} <- @bindings do %>
            <li><%= key %>: <code class="text-teal-300"><%= inspect(value) %></code></li>
          <% end %>
        </ul>
        <div class="flex-1"></div>
        <%= if @suggestions != [] do %>
          <h2 class="font-medium">Suggestions:</h2>
        <% else %>
          <%= if @show_contextual_info do %>
            <%= Phoenix.HTML.raw @show_contextual_info %>
          <% else %>
            <p>[TAB]: suggestions</p>
          <% end %>
        <% end %>
        <ul>
          <%= for suggestion <- @suggestions do %>
            <li><%= suggestion %></li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  defp splitted_command(command) do
    ContextualHelp.compute(command)
  end

  defp render_command_inline_help(assigns, part, docs) do
    ~L"""
      <span
        phx-click="show_contextual_info"
        phx-value-doc="<%= docs %>"
        class="text-green-400 cursor-pointer"
      ><%= part %></span>
    """
  end

  def mount(_session, socket) do
    {:ok,
     assign(
       socket,
       output: [],
       bindings: [],
       history: [],
       history_counter: 0,
       suggestions: [],
       input_value: "",
       show_contextual_info: []
     )}
  end

  # TAB KEY
  def handle_event("suggest", %{"keyCode" => 9, "value" => value}, socket) do
    suggestions = socket.assigns.history |> Enum.filter(&String.starts_with?(&1, value))

    case suggestions do
      [suggestion] -> {:noreply, socket |> assign(input_value: suggestion, suggestions: [])}
      suggestions -> {:noreply, socket |> assign(suggestions: suggestions, input_value: "")}
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

    {:noreply, socket |> assign(input_value: input_value, history_counter: new_counter)}
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

    {:noreply, socket |> assign(input_value: input_value, history_counter: new_counter)}
  end

  def handle_event("suggest", _key, socket) do
    {:noreply, socket |> assign(history_counter: -1)}
  end

  def handle_event("execute", %{"command" => command}, socket) do
    history =
      if socket.assigns.history == [] do
        [command]
      else
        [command | socket.assigns.history]
      end

    case execute_command(command, socket.assigns.bindings) do
      {:ok, result, bindings} ->
        {:noreply,
         socket
         |> append_output(:ok, command, result)
         |> assign(bindings: bindings)
         |> assign(history: history)
         |> assign(suggestions: [])
         |> assign(input_value: "")}

      {:error, error} ->
        {:noreply,
         socket
         |> append_output(:error, command, error)
         |> assign(history: history)
         |> assign(suggestions: [])
         |> assign(input_value: "")}
    end
  end

  def handle_event("show_contextual_info", %{"doc" => doc}, socket) do
    {:noreply, socket |> assign(show_contextual_info: doc)}
  end

  defp execute_command(command, bindings) do
    {result, bindings} = Code.eval_string(command, bindings)
    {:ok, inspect(result), bindings}
  catch
    kind, error ->
      error = Exception.normalize(kind, error)
      {:error, inspect(error)}
  end

  defp append_output(socket, status, command, result_or_error) do
    new_output = socket.assigns.output ++ [build_output(status, command, result_or_error)]
    new_output = Enum.take(new_output, -@console_buffer)
    assign(socket, output: new_output)
  end

  defp build_output(:ok, command, result), do: %Output{command: command, result: result}
  defp build_output(:error, command, error), do: %Output{command: command, error: error}

  defp print_prompt, do: "> "
end
