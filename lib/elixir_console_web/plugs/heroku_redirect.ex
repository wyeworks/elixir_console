defmodule ElixirConsoleWeb.HerokuRedirect do
  @moduledoc """
  Redirect to our custom domain if the app is accessed using the Heroku domain
  """

  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    if configured_host() != conn.host do
      conn
      |> put_resp_header("location", redirect_url())
      |> send_resp(:moved_permanently, "")
      |> halt()
    else
      conn
    end
  end

  defp redirect_url do
    URI.to_string(%URI{
      host: configured_host(),
      scheme: configured_scheme()
    })
  end

  defp configured_host, do: get_from_configured_url(:host, "localhost")
  defp configured_scheme, do: get_from_configured_url(:scheme, "https")

  defp get_from_configured_url(key, default) do
    Keyword.get(ElixirConsoleWeb.Endpoint.config(:url), key, default)
  end
end
