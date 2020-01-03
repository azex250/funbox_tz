defmodule ProjectsStore do
  use Agent

  @type projects_store :: []

  @spec start_link(store :: projects_store) :: Agent.on_start
  def start_link(store\\[]) do
    Agent.start_link(fn -> store end, name: __MODULE__)
  end

  @spec get :: projects_store
  def get do
    Agent.get(__MODULE__, & &1)
  end

  @spec put(store :: projects_store) :: :ok
  def put(store) do
    Agent.update(__MODULE__, fn _ -> store end)
  end
end

defmodule Hello.LoaderTest do
  use ExUnit.Case, async: true
  doctest Hello.RequestUtils
  import Mock

  @markdown %HTTPoison.Response{
    status_code: 200,
    headers: [],
    body: """
    ## Actors
    *Libraries and tools for working with actors and such.*

    * [dflow](https://github.com/dalmatinerdb/dflow) - Pipelined flow processing engine.
    """
  }

  @project %HTTPoison.Response{
    status_code: 200,
    headers: [],
    body: """
    {
      "name": "dflow",
      "html_url": "https://github.com/dalmatinerdb/dflow",
      "description": "Dalmatiner flow processing library.",
      "stargazers_count": 10,
      "pushed_at": "2017-09-26T22:44:20Z"
    }
    """
  }

  test "load_doc" do
    with_mock HTTPoison, [ get: fn
      ("https://api.github.com/repos/dalmatinerdb/dflow", _headers) -> {:ok, @project}
      ("https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md", _headers) -> {:ok, @markdown}
    end] do
      ProjectsStore.start_link()
      Hello.Loader.start_link(Hello.ProjectsStore)
      Hello.Loader.subscribe(ProjectsStore)
      Hello.Loader.reload()
      :timer.sleep(1000)
      assert [{%{
       desc: "Libraries and tools for working with actors and such.",
       topic: "Actors"
      }, %{
       desc: "Dalmatiner flow processing library.",
       href: "https://github.com/dalmatinerdb/dflow",
       last_commit: "2017-09-26T22:44:20Z",
       name: "dflow",
       stars: 10
      }}] = ProjectsStore.get()
    end
  end
end
