defmodule CnsUi.Clients.HTTP do
  @moduledoc """
  Minimal HTTP client wrapper to keep LiveViews decoupled from transport details.
  """
  require Logger

  @default_headers [{"content-type", "application/json"}]

  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(url, opts \\ []) do
    headers = build_headers(opts)

    with {:ok, %Finch.Response{status: status, body: body}} <-
           request(:get, url, headers, nil, opts) do
      decode_response(status, body)
    end
  end

  @spec post(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def post(url, body, opts \\ []) do
    headers = build_headers(opts)
    payload = Jason.encode!(body)

    with {:ok, %Finch.Response{status: status, body: body}} <-
           request(:post, url, headers, payload, opts) do
      decode_response(status, body)
    end
  end

  defp request(method, url, headers, body, opts) do
    finch = Keyword.get(opts, :finch, CnsUi.Finch)
    Logger.debug("HTTP #{method} #{url}", category: :cns_client)

    method
    |> Finch.build(url, headers, body)
    |> Finch.request(finch)
  end

  defp build_headers(opts) do
    api_key = Keyword.get(opts, :api_key) || System.get_env("CNS_API_KEY")
    auth_header = if api_key, do: [{"authorization", "Bearer #{api_key}"}], else: []

    @default_headers
    |> Kernel.++(auth_header)
    |> Kernel.++(Keyword.get(opts, :headers, []))
  end

  defp decode_response(status, body) when status in 200..299 do
    case Jason.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      _ -> {:ok, %{}}
    end
  end

  defp decode_response(status, body), do: {:error, {:http_error, status, body}}
end
