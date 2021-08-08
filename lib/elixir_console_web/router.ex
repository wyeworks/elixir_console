defmodule ElixirConsoleWeb.Router do
  use ElixirConsoleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ElixirConsoleWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElixirConsoleWeb do
    pipe_through :browser

    live "/", ConsoleLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElixirConsoleWeb do
  #   pipe_through :api
  # end
end
