defmodule Hello.RequestUtils do
  @type response :: {:ok, HTTPoison.body} | :not_found | :error

  @spec request(url :: String.t, headers :: HTTPoison.headers) :: response
  def request(url, headers \\ []) do
    case HTTPoison.get(url, headers) |> extract_body() do
      {:ok, body} -> {:ok, body}
      {:moved, new_url} -> request(new_url, headers)
      error -> error
    end
  end

  defp extract_body({:ok, %HTTPoison.Response{status_code: 200, body: body}}), do: {:ok, body}
  defp extract_body({:ok, %HTTPoison.Response{status_code: 404}}), do: :not_found
  defp extract_body({:ok, %HTTPoison.Response{status_code: 301, headers: headers}}) do
    resolve = fn
      {_, url} ->  {:moved, url}
      _ -> :error
    end
    Enum.find(headers, &match?({"Location", _}, &1)) |> resolve.()
  end
  defp extract_body(_), do: :error
end
