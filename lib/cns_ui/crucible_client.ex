defmodule CnsUi.CrucibleClient do
  @moduledoc """
  Lightweight HTTP + PubSub client for the Crucible Framework API.

  All endpoints are driven by `CRUCIBLE_API_URL` and `CRUCIBLE_API_TOKEN`
  environment variables (configured via `:cns_ui, :crucible_api`).
  """

  require Logger

  @type job_response :: map()

  @doc """
  Creates a training job in Crucible.

  Expects a map payload that Crucible understands (dataset/model/hparams metadata).
  """
  @spec create_job(map()) :: {:ok, job_response()} | {:error, term()}
  def create_job(payload) when is_map(payload) do
    with {:ok, url} <- build_url("/api/jobs"),
         {:ok, body} <- Jason.encode(payload),
         {:ok, response} <- request(:post, url, body),
         {:ok, decoded} <- decode_response(response) do
      {:ok, decoded}
    else
      {:error, reason} ->
        Logger.warning("Crucible job creation failed: #{inspect(reason)}")
        {:error, reason}

      {:http_error, status, body} ->
        Logger.warning("Crucible job creation returned #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}
    end
  end

  @doc """
  Fetches a single Crucible job by id.
  """
  @spec get_job(String.t()) :: {:ok, job_response()} | {:error, term()}
  def get_job(job_id) when is_binary(job_id) do
    with {:ok, url} <- build_url("/api/jobs/#{job_id}"),
         {:ok, response} <- request(:get, url, nil),
         {:ok, decoded} <- decode_response(response) do
      {:ok, decoded}
    else
      {:error, reason} ->
        Logger.warning("Crucible job fetch failed: #{inspect(reason)}")
        {:error, reason}

      {:http_error, status, body} ->
        Logger.warning("Crucible job fetch returned #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}
    end
  end

  @doc """
  Subscribes to Crucible PubSub updates for a job if a PubSub name is configured.
  """
  @spec subscribe_job(String.t()) :: :ok | {:error, term()}
  def subscribe_job(job_id) when is_binary(job_id) do
    case pubsub_name() do
      nil ->
        {:error, :pubsub_not_configured}

      pubsub ->
        if Process.whereis(pubsub) do
          Phoenix.PubSub.subscribe(pubsub, "training:#{job_id}")
          :ok
        else
          {:error, :pubsub_unavailable}
        end
    end
  end

  defp request(method, url, body) do
    method
    |> Finch.build(url, headers(), body)
    |> Finch.request(CnsUi.Finch)
  end

  defp headers do
    token = token()

    base_headers = [
      {"content-type", "application/json"},
      {"user-agent", "cns-ui"}
    ]

    if token do
      [{"authorization", "Bearer #{token}"} | base_headers]
    else
      base_headers
    end
  end

  defp decode_response(%Finch.Response{status: status, body: body})
       when status in 200..299 do
    Jason.decode(body)
  end

  defp decode_response(%Finch.Response{status: status, body: body}) do
    {:http_error, status, safe_decode(body)}
  end

  defp build_url(path) do
    case base_url() do
      nil -> {:error, :missing_base_url}
      base -> {:ok, URI.merge(base, path) |> URI.to_string()}
    end
  end

  defp base_url do
    Application.get_env(:cns_ui, :crucible_api, []) |> Keyword.get(:url)
  end

  defp token do
    Application.get_env(:cns_ui, :crucible_api, []) |> Keyword.get(:token)
  end

  defp pubsub_name do
    Application.get_env(:cns_ui, :crucible_api, []) |> Keyword.get(:pubsub)
  end

  defp safe_decode(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      _ -> body
    end
  end
end
