defmodule ElixirConsoleWeb.ConsoleView do
  use ElixirConsoleWeb, :view
  import Phoenix.LiveView.Helpers, only: [live_component: 3]

  alias ElixirConsoleWeb.ConsoleLive.{CommandInputComponent, HistoryComponent, SidebarComponent}

  def print_prompt, do: "> "
end
