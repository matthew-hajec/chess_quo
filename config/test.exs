import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chess_quo, ChessQuoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "lGnpp6FJTuNb5Dvp6EleljqjTZ23TzQKJm6MQS+vdiymAZM10ZmFsq30xk6e4XBz",
  server: false

# In test we don't send emails
config :chess_quo, ChessQuo.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
