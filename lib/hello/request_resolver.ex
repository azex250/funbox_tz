defmodule Hello.RequestResolver do
  alias Hello.RequestResolver.Utils, as: Utils

  def start() do
    spawn(fn -> loop([], [], []) end)
  end

  defp loop(fallback_queue, state, subs) do
    receive do
      :fallback ->
        {fb, new_state} = fallback(fallback_queue, state)
        Enum.each(subs, &send(&1, {:update, new_state}))
        IO.inspect(new_state)
        loop(fb, new_state, subs)
      :reload ->
        case reload() do
          {:ok, new_state, errors} ->
            Enum.each(subs, &send(&1, {:update, new_state}))
            IO.inspect(new_state)
            loop(errors, new_state, subs)
          {:error, req} -> loop([req], state, subs)
        end
      {:subscribe, pid} ->
        loop(fallback_queue, state, [pid | subs])
      {:req_failed, req} -> loop([req | fallback_queue], state, subs)
      error -> IO.inspect(error)
    end
  end

  defp fallback([%{type: :load} | _], state) do
    case reload() do
      {:ok, new_state, errors} -> { errors, new_state }
      {:error, req} -> {[req], state}
    end
  end

  defp fallback([], state) do
    {[], state}
  end

  defp fallback(fb_q, state) do
    case Enum.find(fb_q, &match?(%{type: :load, url: _}, &1)) do
      %{type: :load, url: _} = v -> fallback([v], state)
      _ ->
        updated = Utils.process_links(fb_q, [], fn %{url: link} -> Utils.get_stars(link) end)
        stars = updated |>
          Enum.filter(&match?({:stars, _, _}, &1)) |>
          Enum.map( fn {:stars, k, v} -> {k, v} end) |>
          Map.new()

        errors = updated |>
          Enum.filter(&match?({:req_failed, _}, &1)) |>
          Enum.map( fn {:req_failed, v} -> v end)
        {errors,  %{state | stars: Map.merge(state.stars, stars)}}
    end
  end

  defp reload() do
    req = %{
      url: "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md",
      type: :load
    }

    case Utils.request(req.url) |> Utils.parse_markdown() |> Utils.load_stars() do
      {:ok, _, _} = res -> res
      _ -> {:error, req}
    end
  end
end

defmodule Hello.RequestResolver.Utils do
  def request(url, headers \\ []) do
    case HTTPoison.get(url, headers, hackney: [pool: :defaul]) |> extract_body() do
      {:ok, body} -> {:ok, body}
      {:moved, new_url} -> request(new_url, headers)
      _ -> :error
    end
  end

  defp extract_body({:ok, %HTTPoison.Response{status_code: 200, body: body}}), do: {:ok, body}
  defp extract_body({:ok, %HTTPoison.Response{status_code: 301, headers: headers}}) do
    resolve = fn
      {_, url} ->  {:moved, url}
      _ -> :error
    end
    Enum.find(headers, &match?({"Location", _}, &1)) |> resolve.()
  end
  defp extract_body(_), do: :error

  def parse_markdown({:ok, body}) do
      raw_ast = Earmark.as_ast(body)
      case raw_ast do
        {:ok, ast, _} -> parse_ast(ast, []) |> extract_stars
        _ -> :error
      end
  end

  def parse_markdown(_), do: :error

  defp parse_ast(ast, res) do
    case ast do
      [
        {"h2", _, [title]},
        {"p", [], [{"em", [], [desc]}]},
        {"ul", [], links}
        | tail
      ] -> parse_ast(tail, [%{title: title, desc: desc, links: parse_links(links)} | res])
      [_ | tail] -> parse_ast(tail, res)
      [] -> {:ok, res}
    end
  end

  defp parse_links(links) do
    valid_link = &match?([_, "github.com" | _], &1)

    filter = fn
      {"li", [], [{"a", [{"href", href}], [_]}, _]} -> Path.split(href) |> valid_link.()
      _ -> :false
    end

    mapper = fn
       {"li", [], [{"a", [{"href", href}], [name]}, desc]} -> %{href: href, name: name, desc: desc}
    end

    Enum.filter(links, filter) |> Enum.map(mapper)
  end

  defp extract_stars({:ok, ast}) do
    links_reducer = fn
      %{href: href}, acc -> [ {href, nil} | acc]
    end

    ast_reducer = fn
      %{links: links}, acc -> acc ++  Enum.reduce(links, [], links_reducer)
    end

    { :ok, %{doc: ast, stars: Enum.reduce(ast, [], ast_reducer) |> Map.new } }
  end

  def load_stars({:ok, ast}) do
    updated = process_links(Map.keys(ast.stars), [], &get_stars/1)

    stars = updated |> Enum.filter(&match?({:stars, _, _}, &1)) |>
    Enum.map( fn {:stars, k, v} -> {k, v} end) |>
    Map.new()

    errors = updated |> Enum.filter(&match?({:req_failed, _}, &1)) |>
    Enum.map( fn {:req_failed, v} -> v end)

    {:ok, %{ast | stars: Map.merge(ast.stars, stars)}, errors}
  end

  def load_stars(_), do: :error

  def get_stars(url) do
    req = %{
      url: url,
      type: :load_star
    }

    [_, _, user, repo | _] = Path.split(url)
    cr = "azex250:e3a93fb5618a9230346afb7cdeb02c5f9d1d70e9" |> Base.encode64()
    headers = [{"Authorization", "Basic #{cr}"}]
    request("https://api.github.com/repos/#{user}/#{repo}", headers) |> process_star_resp(req)
  end

  defp process_star_resp({:ok, body}, req), do: Jason.decode(body) |> parse_stars(req.url)
  defp process_star_resp(:error, req) do
    {:req_failed, req}
  end

  defp parse_stars({:ok, %{"stargazers_count" => stars}}, url) do
    {:stars, url, stars}
   end
  defp parse_stars(_, _), do: :error

  def process_links([], res, _), do: res
  def process_links(l, res, f) do
    process_link = fn
      link -> Task.async(fn -> f.(link) end)
    end

    {h, t} = Enum.split(l, 25)
    new_res = Enum.map(h, process_link) |> Enum.map(&Task.await/1)
    process_links(t, res ++ new_res, f)
  end
end
