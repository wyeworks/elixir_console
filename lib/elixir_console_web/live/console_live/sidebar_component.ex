defmodule ElixirConsoleWeb.ConsoleLive.SidebarComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(ElixirConsoleWeb.ConsoleView, "sidebar.html", assigns)
  end
end
