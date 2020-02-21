defmodule ElixirConsoleWeb.ConsoleLive.HistoryComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(ElixirConsoleWeb.ConsoleView, "history.html", assigns)
  end
end
