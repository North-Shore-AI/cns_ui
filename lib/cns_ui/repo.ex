defmodule CnsUi.Repo do
  use Ecto.Repo,
    otp_app: :cns_ui,
    adapter: Ecto.Adapters.Postgres
end
