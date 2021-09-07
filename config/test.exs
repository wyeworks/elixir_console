use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elixir_console, ElixirConsoleWeb.Endpoint,
  http: [port: 4002],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

config :wallaby, chromedriver: [headless: System.get_env("HEADLESS") != "false"]
