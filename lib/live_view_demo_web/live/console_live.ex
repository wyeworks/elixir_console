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
              <div class="text-gray-300 font-medium"><%= print_prompt() %><%= output.command %></div>
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
          <p>[TAB]: suggestions</p>
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

  def mount(_session, socket) do
    {:ok, assign(socket, output: [], bindings: [], history: [], suggestions: [])}
  end

  def handle_event("suggest", %{"keyCode" => 9, "value" => value}, socket) do
    IO.inspect("a")
    suggestions = socket.assigns.history |> Enum.filter(&(String.starts_with?(&1, value)))

    {:noreply, socket |> assign(suggestions: suggestions)}
  end

  def handle_event("suggest", _key, socket) do
    {:noreply, socket}
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
         |> assign(suggestions: [])}

      {:error, error} ->
        {:noreply,
         socket
         |> append_output(:error, command, error)
         |> assign(history: history)
         |> assign(suggestions: [])}
    end
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
