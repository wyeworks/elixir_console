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
        <input type="text" name="command"/>
      </form>
    </div>
    <div>
      <%= for {key, value} <- @bindings do %>
        <p><%= key %>: <code><%= inspect(value) %></code></p>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, output: [], bindings: [])}
  end

  def handle_event("execute", %{"command" => command}, socket) do
    case execute_command(command, socket.assigns.bindings) do
      {:ok, result, bindings} ->
        {:noreply,
         socket
         |> append_output(:ok, command, result)
         |> assign(bindings: bindings)}

      {:error, error} ->
        {:noreply, append_output(socket, :error, command, error)}
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
