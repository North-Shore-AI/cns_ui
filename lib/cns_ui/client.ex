defmodule CnsUi.Client do
  @moduledoc """
  API client facade for Crucible Framework endpoints with instrumentation and configurable transport.
  """
  alias CnsUi.Clients.HTTP

  @type run_payload :: map()
  @type list_opts :: keyword()

  @spec list_runs(list_opts()) :: {:ok, list()} | {:error, term()}
  def list_runs(opts \\ []) do
    params = Keyword.get(opts, :filters, %{})

    instrument(:list_runs, %{params: params}, fn ->
      with {:ok, base_url} <- fetch_base_url(opts) do
        url = base_url <> "/v1/runs" <> query_string(params)
        HTTP.get(url, http_opts(opts))
      else
        {:error, :missing_base_url} -> {:ok, stub_runs(params)}
        error -> error
      end
    end)
  end

  @spec create_run(run_payload(), list_opts()) :: {:ok, map()} | {:error, term()}
  def create_run(payload, opts \\ []) when is_map(payload) do
    instrument(:create_run, %{payload: Map.take(payload, ["id", "name", "experiment_id"])}, fn ->
      with {:ok, base_url} <- fetch_base_url(opts) do
        HTTP.post(base_url <> "/v1/jobs", payload, http_opts(opts))
      else
        {:error, :missing_base_url} ->
          {:ok, Map.merge(%{"id" => "stub_run", "status" => "pending"}, payload)}

        error ->
          error
      end
    end)
  end

  @spec stream_run(String.t() | integer(), list_opts()) :: {:ok, String.t()} | {:error, term()}
  def stream_run(run_id, opts \\ []) do
    topic = "run:#{run_id}"

    instrument(:stream_run, %{run_id: run_id}, fn ->
      if Keyword.get(opts, :subscribe?, true) do
        Phoenix.PubSub.subscribe(CnsUi.PubSub, topic)
      end

      {:ok, topic}
    end)
  end

  defp fetch_base_url(opts) do
    base_url =
      opts
      |> client_opts()
      |> Keyword.get(:base_url) || System.get_env("CRUCIBLE_API_BASE_URL")

    case base_url do
      nil -> {:error, :missing_base_url}
      url -> {:ok, String.trim_trailing(url, "/")}
    end
  end

  defp http_opts(opts) do
    config = client_opts(opts)
    token = Keyword.get(config, :api_token) || System.get_env("CRUCIBLE_API_TOKEN")
    base_headers = Keyword.get(config, :headers, [])

    []
    |> Keyword.put(:api_key, token)
    |> Keyword.put(:headers, base_headers)
  end

  defp client_opts(opts), do: Keyword.merge(Application.get_env(:cns_ui, :client, []), opts)

  defp query_string(%{} = params) when map_size(params) == 0, do: ""

  defp query_string(%{} = params),
    do: "?" <> URI.encode_query(params)

  defp query_string(_), do: ""

  defp stub_runs(_params) do
    [
      %{
        "id" => "cns-run-1",
        "experiment_id" => "cns-exp-1",
        "status" => "running",
        "progress" => 0.42,
        "domain" => "cns"
      },
      %{
        "id" => "cns-run-2",
        "experiment_id" => "cns-exp-1",
        "status" => "pending",
        "progress" => 0.0,
        "domain" => "cns"
      }
    ]
  end

  defp instrument(event, meta, fun) do
    start = System.monotonic_time()

    result =
      try do
        fun.()
      rescue
        exception ->
          :telemetry.execute(
            [:cns_ui, :api, event],
            %{
              duration_ms: duration_ms(start),
              result: :error
            },
            Map.put(meta, :error, exception)
          )

          reraise(exception, __STACKTRACE__)
      else
        value ->
          :telemetry.execute(
            [:cns_ui, :api, event],
            %{
              duration_ms: duration_ms(start),
              result: result_flag(value)
            },
            meta
          )

          value
      end

    result
  end

  defp duration_ms(start),
    do: System.convert_time_unit(System.monotonic_time() - start, :native, :millisecond)

  defp result_flag({:ok, _}), do: :ok
  defp result_flag({:error, _}), do: :error
  defp result_flag(_), do: :ok
end
