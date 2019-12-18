defmodule ElixirConsoleWeb.HerokuRedirect do
  @moduledoc """
  Redirect to our custom domain if the app is accessed using the Heroku domain
  """

  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    if configured_url() != conn.host do
      conn
      |> put_resp_header("Location", redirect_url())
      |> send_resp(:moved_permanently, "")
      |> halt()
    else
      conn
    end
  end

  defp configured_url, do: ElixirConsoleWeb.Endpoint.config(:url)[:host] || "localhost:4001"

  defp redirect_url do
    %URI{
      host: configured_url(),
      scheme: ElixirConsoleWeb.Endpoint.config(:url)[:scheme] || "https"
    }
    |> URI.to_string()
  end
end
