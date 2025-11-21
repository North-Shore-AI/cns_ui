import Config

config :cns_ui, CnsUi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cns_ui_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :cns_ui, CnsUiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test_secret_key_base_that_is_at_least_64_bytes_long_for_security_purposes_in_test",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
