import Config

test_db_host = System.get_env("POSTGRES_HOST") || "localhost"
test_db_port = String.to_integer(System.get_env("POSTGRES_PORT") || "5432")
test_db_user = System.get_env("POSTGRES_USER") || "postgres"
test_db_pass = System.get_env("POSTGRES_PASSWORD") || "postgres"
test_db_partition = System.get_env("MIX_TEST_PARTITION") || ""

test_db_name =
  case System.get_env("POSTGRES_DB") do
    nil -> "cns_ui_test#{test_db_partition}"
    db -> "#{db}#{test_db_partition}"
  end

config :cns_ui, CnsUi.Repo,
  username: test_db_user,
  password: test_db_pass,
  hostname: test_db_host,
  port: test_db_port,
  database: test_db_name,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :cns_ui, CnsUiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test_secret_key_base_that_is_at_least_64_bytes_long_for_security_purposes_in_test",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
