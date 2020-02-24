defmodule ElixirConsoleWeb.ConsoleLive.HistoryComponent do
  @moduledoc """
  Live component module that implements the portion of the UI where previous
  commands and results are displayed.
  """

  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(ElixirConsoleWeb.ConsoleView, "history.html", assigns)
  end
end
