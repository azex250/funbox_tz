defmodule Hello.Parser do
  def parse_markdown({:ok, doc}) do
    Earmark.as_ast(doc) |> parse_ast() |> extract_href()
  end
  def parse_markdown(_), do: :error

  def parse_stars({:ok, body}, req) do
     case Jason.decode(body) do
       {:ok, %{"stargazers_count" => stars, "pushed_at" => last_commit}} -> {:ok, {req.url, {stars, last_commit}}}
       _ -> {:error, req}
     end
   end
  def parse_stars(err, req), do: {err, req}

  def add_stars(stars, doc) do
    link_mapper = fn %{href: href, stars: old_stars, last_commit: commit} = link ->
      {new_stars, last_commit} = Map.get(stars, href, {old_stars, commit})
      %{link | stars: new_stars, last_commit: last_commit}
    end

    doc_mapper = fn
      %{links: links} = root -> %{root | links: Enum.map(links, link_mapper)}
    end

    Enum.map(doc, doc_mapper)
  end

  def filter_by_stars(doc, min_stars) do
    link_filter = fn
      %{stars: nil} -> false
      %{stars: stars} -> stars >= min_stars
    end

    doc_mapper = fn
      %{links: links} = root -> %{root | links: Enum.filter(links, link_filter)}
    end

    doc_filter = fn
      %{links: []} -> false
      %{links: _} -> true
    end

    doc |> Enum.map(doc_mapper) |> Enum.filter(doc_filter)
  end

  defp parse_ast({:ok, ast, _}), do: parse_ast(ast, [])
  defp parse_ast(_), do: :error
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
       {"li", [], [{"a", [{"href", href}], [name]}, desc]} ->
          %{last_commit: nil, stars: nil, href: href, name: name, desc: desc}
    end

    Enum.filter(links, filter) |> Enum.map(mapper)
  end

  defp extract_href({:ok, ast}) do
    links_reducer = fn
      %{href: href}, acc -> [ href | acc]
    end

    ast_reducer = fn
      %{links: links}, acc -> acc ++ Enum.reduce(links, [], links_reducer)
    end

    { :ok, %{doc: ast, stars: Enum.reduce(ast, [], ast_reducer) } }
  end
  defp extract_href(_), do: :error
end
