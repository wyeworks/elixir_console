defmodule ElixirConsoleWeb.ConsoleLive.SidebarComponent do
  @moduledoc """
  Live component module that implements the portion of the UI corresponding to
  the sidebar. It displays the bindings, Elixir functions help and some static
  information.
  """

  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(ElixirConsoleWeb.ConsoleView, "sidebar.html", assigns)
  end
end
