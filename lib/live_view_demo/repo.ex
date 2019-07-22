defmodule LiveViewDemo.Repo do
  use Ecto.Repo,
    otp_app: :live_view_demo,
    adapter: Ecto.Adapters.Postgres
end
