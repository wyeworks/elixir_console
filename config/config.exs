# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :elixir_console, ElixirConsoleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "xkn0Oy0t0ydkJkKxKwFVJ36lc5MX7kHtdo+4vtEVqGrBNN/Kv4a9GIGqbx6CHlVw",
  render_errors: [view: ElixirConsoleWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ElixirConsole.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "7vohZO+j"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
