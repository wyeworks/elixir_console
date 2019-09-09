defmodule LiveViewDemoWeb.ConsoleLive do
  use Phoenix.LiveView

  @console_buffer 5

  defmodule Output do
    @enforce_keys [:command]
    defstruct [:command, :result, :error]
  end

  def render(assigns) do
    ~L"""
    <div>
      <form phx-submit="execute">
        <pre>
          <%= for output <- @output do %>
            <strong><%= print_prompt() %></strong><%= output.command %>
            <%= if output.result do output.result end %>
            <%= if output.error do %><span style="background-color: #edcacd"><%= output.error %></span><% end %>
          <% end %>
        </pre>
        <input type="text" name="command" id="commandInput" phx-keydown="suggest"/>
      </form>
    </div>
    <div style="display: flex; flex-wrap: wrap">
      <%= for suggestion <- @suggestions do %>
        <div style="margin-right: 10px"><%= suggestion %></div>
      <% end %>
    </div>
    <div>
      <%= for {key, value} <- @bindings do %>
        <p><%= key %>: <code><%= inspect(value) %></code></p>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, output: [], bindings: [], history: [], suggestions: [])}
  end

  def handle_event("suggest", %{"keyCode" => 9, "value" => value}, socket) do
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

  defp print_prompt, do: ">> "
end
