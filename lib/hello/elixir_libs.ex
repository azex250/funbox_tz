defmodule Hello.ElixirLibs do
  def get_libs() do
      "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md" |>
      HTTPoison.get() |>
      extract_body() |>
      parse_markdown() |>
      filter_projects() |>
      get_stars()
  end

  defp extract_body({:ok, %HTTPoison.Response{status_code: 200, body: body}}), do: {:ok, body}
  defp extract_body({:ok, %HTTPoison.Response{status_code: 301, headers: raw_headers}}) do
    headers = Jason.decode!(raw_headers)
    [{"Location", url}] = Enum.filter(headers, fn
      {"Location", _} -> true
      _ -> false
    end)
    HTTPoison.get(url) |> extract_body()
  end

  defp extract_body(_), do: :error

  defp parse_markdown({:ok, body}) do
      raw_ast = Earmark.as_ast(body)
      case raw_ast do
        {:ok, ast, _} -> Hello.ElixirLibs.Parsers.parse_ast(ast, [])
        _ -> :error
      end
  end

  defp parse_markdown(_), do: :error

  defp filter_projects({:ok, projects}) do
    {:ok, Enum.filter(
      projects, fn %{title: title} -> case title do
        "Newsletters" -> false
        "Other Awesome Lists" -> false
        "Reading" -> false
        "Screencasts" -> false
        "Styleguides" -> false
        "Websites" -> false
        _ -> true
      end
    end)}
  end

  defp filter_projects(_), do: :error

  defp get_stars({:ok, projects}) do
    process_link = fn
      %{href: href} = link -> Task.async(fn -> %{link | stars: Hello.ElixirLibs.Parsers.parse_star(href)} end)
    end

    process_proj = fn
      %{links: links} = proj -> %{proj | links: Enum.map(links, process_link) |>  Enum.map(&Task.await/1)}
    end

    Enum.map(projects, process_proj)
  end

  defp get_stars(_), do: :error
end

defmodule Hello.ElixirLibs.Parsers do
  defp extract_body({:ok, %HTTPoison.Response{status_code: 200, body: body}}), do: body
  defp extract_body({:ok, %HTTPoison.Response{status_code: 301, headers: headers}}) do
    [{"Location", url}] = Enum.filter(headers, fn
      {"Location", _} -> true
      _ -> false
    end)
    HTTPoison.get(url) |> extract_body()
  end

  def parse_ast(ast, res) do
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
    valid_link = fn
      [_, "github.com" | _] -> :true
      v ->
        IO.inspect(v)
        false
    end

    filter = fn
      {"li", [], [{"a", [{"href", href}], [_]}, _]} -> Path.split(href) |> valid_link.()
      _ -> :false
    end

    mapper = fn
       {"li", [], [{"a", [{"href", href}], [name]}, desc]} -> %{stars: nil, href: href, name: name, desc: desc}
    end

    Enum.filter(links, filter) |> Enum.map(mapper)
  end

  def parse_star(repo_url) do
    IO.puts(repo_url)
    [_, _, user, repo | _] = Path.split(repo_url)
    "https://api.github.com/repos/#{user}/#{repo}" |>
    HTTPoison.get() |>
    extract_body() |>
    Jason.decode() |>
    get_stars()
  end

  defp get_stars({:ok, %{"stargazers_count" => stars}}), do: stars
  defp get_stars(_), do: :error
end
