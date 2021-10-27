defmodule ElixirConsoleWeb.ConsoleLive.HistoryComponent do
  @moduledoc """
  Live component module that implements the portion of the UI where previous
  commands and results are displayed.
  """

  use Surface.LiveComponent
  import Phoenix.HTML, only: [sigil_e: 2]
  import ElixirConsoleWeb.ConsoleLive.Helpers
  alias ElixirConsole.ContextualHelp

  prop output, :keyword

  @impl true
  def render(assigns) do
    ~F"""
    <div class="p-2" id="commandOutput" phx-update="append">
      <div id="version-info" class="text-gray-400 font-medium">
        <p>Elixir {System.version()}/OTP {System.otp_release()}</p>
      </div>
      {#for output <- @output}
        <div id={"command#{output.id}"} class="text-gray-200 font-medium">
          {print_prompt()}{format_command(output.command)}
        </div>
        <div id={"output#{output.id}"} class="text-teal-300">
          {output.result}
          {#if output.error}
            <span class="text-pink-400">
              {output.error}
            </span>
          {/if}
        </div>
      {/for}
    </div>
    """
  end

  @impl true
  def handle_event(
        "function_link_clicked",
        %{"func_name" => func_name, "header" => header, "doc" => doc, "link" => link},
        socket
      ) do
    send(
      self(),
      {:show_function_docs, %{func_name: func_name, header: header, doc: doc, link: link}}
    )

    {:noreply, socket}
  end

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
    phx-click="function_link_clicked"
    phx-value-func_name="<%= func_name %>"
    phx-value-header="<%= header %>"
    phx-value-doc="<%= docs %>"
    phx-value-link="<%= link %>"
    phx-target="#commandOutput"
    class="<%= inline_help_class_for(function_or_operator) %>"
    ><%= part %></span>}
  end

  defp inline_help_class_for(:function), do: "text-green-400 cursor-pointer underline"
  defp inline_help_class_for(:operator), do: "cursor-pointer"
end
