defmodule LiveViewDemoWeb.PageController do
  use LiveViewDemoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
