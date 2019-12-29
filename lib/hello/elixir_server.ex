defmodule Hello.ElixirServer do
  use GenServer
  alias Hello.AsyncUtils, as: AsyncUtils
  alias Hello.RequestUtils, as: RequestUtils
  alias Hello.Parser, as: Parser

  @api_user "azex250"
  @api_url "https://api.github.com/repos/"
  @api_token "e3a93fb5618a9230346afb7cdeb02c5f9d1d70e9"
  @parser_timeout 300000
  @markdown_url "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"

  def start_link(_params) do
    GenServer.start_link(__MODULE__, {%{}, []}, name: __MODULE__)
  end

  def reload() do
    GenServer.call(__MODULE__, :reload, @parser_timeout)
  end

  def state() do
    GenServer.call(__MODULE__, :state)
  end

  def state(count) do
    GenServer.call(__MODULE__, {:state, count})
  end

  def fallback() do
    GenServer.call(__MODULE__, :fallback, @parser_timeout)
  end

  @impl true
  def init({store, fallback_queue}) do
    {:ok, {store, fallback_queue}}
  end

  @impl true
  def handle_call(:state, _from, {store, _} = state) do
    {:reply, store, state}
  end

  @impl true
  def handle_call({:state, stars}, _from, {store, _} = state) do
    {:reply, Parser.filter_by_stars(store, stars), state}
  end

  @impl true
  def handle_call(:reload, _from, {store, _}) do
    case load_doc() do
      {:ok, new_store, errors} -> {:reply, {:ok, new_store}, {new_store, errors}}
      {:error, req} -> {:reply, :error, {store, [req]}}
    end
  end

  @impl true
  def handle_call(:fallback, _from, {store, fallback_queue}) do
    {fb_q, new_store} = fallback(fallback_queue, store)
    {:reply, {:ok, new_store}, {new_store, fb_q}}
  end

  defp fallback([%{type: :load} | _], store) do
    case load_doc() do
      {:ok, new_store, errors} -> { errors, new_store }
      {:error, req} -> {[req], store}
    end
  end

  defp fallback([], state) do
    {[], state}
  end

  defp fallback(fb_q, state) do
      hrefs = Enum.map(fb_q, fn %{url: link} -> link end)
      {:ok, new_state, errors} = add_stars({:ok, %{stars: hrefs, doc: state}})
      {errors,  new_state}
  end

  defp load_doc() do
    case RequestUtils.request(@markdown_url) |> Parser.parse_markdown() |> add_stars() do
      {:ok, _, _} = res -> res
      _ -> {:error, %{type: :load}}
    end
  end

  defp add_stars({:ok, %{doc: doc, stars: hrefs}}) do
      {stars, errors} = load_stars(hrefs)

      {:ok, Parser.add_stars(stars, doc), errors}
  end
  defp add_stars(_), do: :error

  defp load_stars(urls) do
    responses = AsyncUtils.process(urls, &request_star/1) |>
      Enum.map(fn {res, req} -> Parser.parse_stars(res, req) end)

    stars = responses |>
      Enum.filter(&match?({:ok, _}, &1)) |>
      Enum.map( fn {_, kv} -> kv end) |>
      Map.new()

    errors = responses |>
      Enum.filter(&match?({:error, _}, &1)) |>
      Enum.map( fn {_, req} -> req end)

    {stars, errors}
  end

  defp request_star(url) do
    req = %{
      url: url,
      type: :load_star
    }

    [_, _, user, repo | _] = Path.split(url)
    cr = @api_user <> ":" <> @api_token |> Base.encode64()
    headers = [{"Authorization", "Basic #{cr}"}]

    {RequestUtils.request(@api_url <> "#{user}/#{repo}", headers), req}
  end
end
