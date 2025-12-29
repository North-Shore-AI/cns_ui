import Config

if System.get_env("PHX_SERVER") do
  config :cns_ui, CnsUiWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :cns_ui, CnsUi.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :cns_ui, CnsUiWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end

# Crucible API + PubSub configuration
config :cns_ui, :crucible_api,
  url: System.get_env("CRUCIBLE_API_URL") || "http://localhost:4100",
  token: System.get_env("CRUCIBLE_API_TOKEN"),
  pubsub: System.get_env("CRUCIBLE_PUBSUB_NAME", "CrucibleUI.PubSub") |> String.to_atom()

# Labeling backend mode configuration
# Set LABELING_MODE=anvil to use real Anvil service
labeling_mode =
  case System.get_env("LABELING_MODE") do
    "anvil" -> :anvil
    "local" -> :local
    _ -> :local
  end

config :cns_ui, :labeling_mode, labeling_mode

# Anvil client configuration (used when LABELING_MODE=anvil)
if labeling_mode == :anvil do
  config :ingot,
    anvil_client_adapter: Ingot.AnvilClient.HTTPAdapter,
    anvil_base_url: System.get_env("ANVIL_URL") || "http://localhost:4101",
    default_tenant_id: System.get_env("ANVIL_TENANT_ID") || "cns_ui"
end
