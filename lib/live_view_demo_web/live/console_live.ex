defmodule LiveViewDemoWeb.ConsoleLive do
  use Phoenix.LiveView

  defmodule Output do
    @enforce_keys [:command]
    defstruct [:command, :result, :error]
  end

  def render(assigns) do
    ~L"""
    <div>
      <form phx-submit="execute">
        <input type="text" name="command"/>
        <pre>
          <%= for output <- @output do %>
            <strong><%= print_prompt() %></strong><%= output.command %>
            <%= if output.result do output.result end %>
            <%= if output.error do %><span style="background-color: #edcacd"><%= output.error %></span><% end %>
          <% end %>
        </pre>
      </form>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, output: [], bindings: [])}
  end

  def handle_event("execute", %{"command" => command}, socket) do
    case execute_command(command, socket.assigns.bindings) do
      {:ok, result, bindings} ->
        {:noreply, append_output(socket, :ok, command, result) |> assign(bindings: bindings)}
      {:error, error} -> {:noreply, append_output(socket, :error, command, error)}
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

  defp append_output(socket, :ok, command, result) do
    new_output = [
      %Output{command: command, result: result} | socket.assigns.output
    ]
    assign(socket, output: new_output)
  end

  defp append_output(socket, :error, command, error) do
    new_output = [
      %Output{command: command, error: error} | socket.assigns.output
    ]
    assign(socket, output: new_output)
  end

  defp print_prompt, do: ">> "
end
