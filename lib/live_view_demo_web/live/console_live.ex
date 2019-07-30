defmodule LiveViewDemoWeb.ConsoleLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div>
      <form phx-submit="execute">
        <input type="text" name="command" value="<%= @command %>"/>
        <%= if @result do %><pre><%= @result %></pre><% end %>
        <%= if @error do %><pre style="background-color: #edcacd"><%= @error %></pre><% end %>
      </form>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, command: "", error: nil, result: nil)}
  end

  def handle_event("execute", %{"command" => command}, socket) do
    socket = reset_assigns(socket, command)

    case execute_command(command) do
      {:ok, result} -> {:noreply, assign(socket, result: result)}
      {:error, error} -> {:noreply, assign(socket, error: error)}
    end
  end

  defp execute_command(command) do
    {result, _} = Code.eval_string(command)
    {:ok, inspect(result)}
  catch
    kind, error ->
      error = Exception.normalize(kind, error)
      {:error, inspect(error)}
  end

  defp reset_assigns(socket, command) do
    assign(socket,
      command: command,
      error: nil,
      result: nil
    )
  end
end
