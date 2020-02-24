defmodule ElixirConsoleWeb.ConsoleLive.HistoryComponent do
  @moduledoc """
  Live component module that implements the portion of the UI where previous
  commands and results are displayed.
  """

  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(ElixirConsoleWeb.Console.HistoryView, "index.html", assigns)
  end

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
end
