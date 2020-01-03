defmodule Hello.Parser do
  @type response :: Hello.RequestUtils.response
  @type github_topic :: %{title: String.t, desc: String.t}
  @type github_project :: %{
    stars: integer,
    last_commit: String.t,
    href: String.t,
    name: String.t,
    description: String.t,
  }
  @type store_item :: {github_topic, github_project}
  @type projects_store :: list(store_item)

  @spec modify_result(projects_store) :: list
  def modify_result(res) do
    Enum.filter(res, fn {_, v} -> v.stars != nil end) |>
      Enum.group_by(fn {k, _} -> k end, fn {_, v} -> v end) |>
      Enum.map(fn {k, v} -> %{title: k.topic, desc: k.desc, links: v} end) |>
      Enum.sort_by(fn e -> e.title end)
  end

  @spec parse_markdown(response) :: {:ok, projects_store} | :error
  def parse_markdown({:ok, doc}) do
    Earmark.as_ast(doc) |> parse_ast() |> reduce_ast()
  end
  def parse_markdown(_), do: :error

  @spec parse_git_project(response) :: {:ok, github_project} | :not_found | :error
  def parse_git_project({:ok, body}) do
     case Jason.decode(body) do
       {:ok, %{
         "stargazers_count" => stars,
         "pushed_at" => last_commit,
         "name" => name,
         "description" => description,
         "html_url" => href
       }} -> {:ok, %{
         last_commit: last_commit,
         stars: stars,
         name: name,
         desc: description,
         href: href,
       }}
       _ -> :error
     end
  end
  def parse_git_project(:not_found), do: :not_found
  def parse_git_project(_), do: :error

  @spec update_store(new_projects :: list(github_project), store :: projects_store) :: projects_store
  def update_store(new_projects, store) do
    project_map = Enum.map(new_projects, &{&1.href, &1}) |> Map.new

    Enum.map(store, fn
      {topic, project} -> {topic, Map.get(project_map, project.href, project)}
    end)
  end

  @spec filter_by_stars(doc :: projects_store, min_stars :: integer) :: projects_store
  def filter_by_stars(store, min_stars) do
    fn_filter = fn {_, %{stars: stars}} ->
      stars != nil and stars >= min_stars
    end

    store |> Enum.filter(fn_filter)
  end

  @spec parse_ast({:ok, list, any} | any) :: list | :error
  defp parse_ast({:ok, ast, _}), do: parse_ast(ast, [])
  defp parse_ast(_), do: :error
  defp parse_ast(ast, res) do
    case ast do
      [
        {"h2", _, [title]},
        {"p", [], [{"em", [], [desc]}]},
        {"ul", [], links}
        | tail
      ] -> parse_ast(tail, [%{title: title, desc: desc, links: links} | res])
      [_ | tail] -> parse_ast(tail, res)
      [] -> res
    end
  end


  @spec reduce_ast(list | :error) :: {:ok, projects_store} | :error
  defp reduce_ast(:error), do: :error
  defp reduce_ast([]), do: []
  defp reduce_ast(res) do
    case Enum.map(res, fn
      %{title: title, desc: desc, links: links} -> parse_links(links, title, desc)
    end) do
      [] -> []
      list -> {:ok, list |> Enum.reduce(&(&1 ++ &2))}
    end
  end

  @spec parse_links(list, String.t, String.t) :: list(store_item)
  defp parse_links(links, topic, topic_desc) do
    topic = %{topic: topic, desc: topic_desc}
    valid_link = &match?([_, "github.com" | _], &1)
    filter_fn = fn
      {"li", [], [{"a", [{"href", href}], [_]}, _]} -> Path.split(href) |> valid_link.()
      _ -> :false
    end

    mapper_fn = fn {"li", [], [{"a", [{"href", href}], [name]}, desc]} ->
      { topic, %{last_commit: nil, stars: nil, href: href, name: name, desc: desc} }
    end

    Enum.filter(links, filter_fn) |> Enum.map(mapper_fn)
  end
end
