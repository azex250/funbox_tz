defmodule Hello.Loader do
  use GenServer
  alias Hello.AsyncUtils, as: AsyncUtils
  alias Hello.RequestUtils, as: RequestUtils
  alias Hello.Parser, as: Parser

  @type github_project :: Parser.github_project
  @type projects_store :: Parser.projects_store

  @api_user "azex250"
  @api_url "https://api.github.com/repos/"
  @api_token "e3a93fb5618a9230346afb7cdeb02c5f9d1d70e9"
  @markdown_url "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"

  @spec start_link(any) :: GenServer.on_start
  def start_link(_params) do
    GenServer.start_link(__MODULE__, %{subs: [], store: [], errors: []}, name: __MODULE__)
  end

  @spec reload() :: :ok
  def reload() do
    GenServer.cast(__MODULE__, :reload)
  end

  @spec fallback() :: :ok
  def fallback() do
    GenServer.cast(__MODULE__, :fallback)
  end

  @spec subscribe(pid | atom) :: :ok
  def subscribe(sub) do
    GenServer.cast(__MODULE__, {:subscribe, sub})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:subscribe, sub}, state) do
    sub.put(state.store)
    {:noreply, %{state | subs: [sub | state.subs]}}
  end

  @impl true
  def handle_cast(:reload, state) do
    case load_doc() do
      {:ok, store, errors} ->
        Enum.each(state.subs, &(&1.put(store)))
        {:noreply, %{state | errors: errors, store: store}}
      :error -> {:noreply, %{state | errors: :reload}}
    end
  end

  @impl true
  def handle_cast(:fallback, state) do
    case fallback(state.errors, state.store) do
      {:ok, store, errors} ->
        IO.inspect(state.store |> Enum.filter(fn {_, v} -> v.stars != nil end))
        IO.inspect(errors)
        Enum.each(state.subs, &(&1.put(store)))
        {:noreply, %{state | errors: errors, store: store}}
      :error -> {:noreply, state}
    end
  end

  @spec fallback(:reload | list(String.t), projects_store) :: {:ok, projects_store, errors::list(String.t) } | :error
  defp fallback(:reload, _store), do: load_doc()
  defp fallback([], store), do: {:ok, store, []}
  defp fallback(errors, store) do
    {repos, errors} = load_git_repos(errors)
    {:ok, Parser.update_store(repos, store), errors}
  end

  @spec load_doc() :: {:ok, projects_store, error_urls :: list(String.t) } | :error
  defp load_doc() do
    case RequestUtils.request(@markdown_url) |> Parser.parse_markdown() |> update_repos() do
      {:ok, _, _} = res -> res
      _ -> :error
    end
  end

  @spec update_repos({:ok, projects_store} | :error) :: {:ok, projects_store, errors::list(String.t) } | :error
  defp update_repos({:ok, store}) do
    {repos, errors} = Enum.map(store, fn {_, %{href: href}} -> href end) |> load_git_repos()
    {:ok, Parser.update_store(repos, store), errors}
  end
  defp update_repos(:error), do: :error

  @spec load_git_repos(url :: list(String.t)) :: {list(github_project), list(String.t)}
  defp load_git_repos(urls) do
    responses = AsyncUtils.process(urls, &load_git_repo/1)

    repos = responses |>
      Enum.filter(&match?({:ok, _}, &1)) |>
      Enum.map(fn {:ok, res} -> res end)

    errors = responses |>
      Enum.filter(&match?({:error, _}, &1)) |>
      Enum.map( fn {_, url} -> url end)

    {repos, errors}
  end

  @spec load_git_repo(url :: String.t) :: {:ok, github_project} | :not_found | {:error, url :: String.t}
  defp load_git_repo(url) do
    [_, _, user, repo | _] = Path.split(url)
    cr = @api_user <> ":" <> @api_token |> Base.encode64()
    headers = [{"Authorization", "Basic #{cr}"}]

    case RequestUtils.request(@api_url <> "#{user}/#{repo}", headers) |> Parser.parse_git_project do
      :error -> {:error, url}
      res -> res
    end
  end
end
