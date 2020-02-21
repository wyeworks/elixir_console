defmodule ElixirConsoleWeb.ConsoleView do
  use ElixirConsoleWeb, :view

  alias ElixirConsole.ContextualHelp

  def print_prompt, do: "> "

  def format_command(command) do
    for part <- split_command(command) do
      case part do
        {part, help_metadata} ->
          render_command_inline_help(part, help_metadata)

        part ->
          part
      end
    end
  end

  defp split_command(command) do
    ContextualHelp.compute(command)
  end

  defp render_command_inline_help(part, %{
         type: function_or_operator,
         func_name: func_name,
         header: header,
         docs: docs,
         link: link
       }) do
    ~e{<span
    phx-click="show_contextual_info"
    phx-value-func_name="<%= func_name %>"
    phx-value-header="<%= header %>"
    phx-value-doc="<%= docs %>"
    phx-value-link="<%= link %>"
    class="<%= inline_help_class_for(function_or_operator) %>"
    ><%= part %></span>}
  end

  defp inline_help_class_for(:function), do: "text-green-400 cursor-pointer underline"
  defp inline_help_class_for(:operator), do: "cursor-pointer"
end
