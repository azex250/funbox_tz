defmodule Hello.ParserTest do
  use ExUnit.Case
  doctest Hello.Parser

  @valid_elixir_md """
  # Awesome Elixir [![Build Status](https://api.travis-ci.org/h4cc/awesome-elixir.svg?branch=master)](https://travis-ci.org/h4cc/awesome-elixir) [![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
  A curated list of amazingly awesome Elixir libraries, resources, and shiny things inspired by [awesome-php](https://github.com/ziadoz/awesome-php).

  If you think a package should be added, please add a :+1: (`:+1:`) at the according issue or create a new one.

  There are [other sites with curated lists of elixir packages](#other-awesome-lists) which you can have a look at.

  - [Awesome Elixir](#awesome-elixir)
      - [Actors](#actors)
      - [Algorithms and Data structures](#algorithms-and-data-structures)
  - [Resources](#resources)
      - [Books](#books)
  - [Contributing](#contributing)

  ## Actors
  *Libraries and tools for working with actors and such.*

  * [dflow](https://github.com/dalmatinerdb/dflow) - Pipelined flow processing engine.
  * [exactor](https://github.com/sasa1977/exactor) - Helpers for easier implementation of actors in Elixir.

  ## Editors
  *Editors and IDEs useable for Elixir/Erlang*

  * [Alchemist](https://github.com/tonini/alchemist.el) - Elixir Tooling Integration Into Emacs.
  * [Alchemist-Server](https://github.com/tonini/alchemist-server) - Editor/IDE independent background server to inform about Elixir mix projects.

  ## Newsletters
  *Useful Elixir-related newsletters.*

  * [Elixir Digest](http://elixirdigest.net) - A weekly newsletter with the latest articles on Elixir and Phoenix.
  * [Elixir Radar](http://plataformatec.com.br/elixir-radar) - The "official" Elixir newsletter, published weekly via email by Plataformatec.
  * [ElixirWeekly](https://elixirweekly.net) - The Elixir community newsletter, covering stuff you easily miss, shared on [ElixirStatus](http://elixirstatus.com) and the web.

  ## Other Awesome Lists
  *Other amazingly awesome lists can be found at [jnv/lists](https://github.com/jnv/lists#lists-of-lists) or [bayandin/awesome-awesomeness](https://github.com/bayandin/awesome-awesomeness#awesome-awesomeness).*

  * [Awesome Elixir and CQRS](https://github.com/slashdotdash/awesome-elixir-cqrs) - A curated list of awesome Elixir and Command Query Responsibility Segregation (CQRS) and event sourcing resources.

  ## Reading
  *Elixir-releated reading materials.*

  * [Discover Elixir & Phoenix](https://www.ludu.co/course/discover-elixir-phoenix/) - An online course that teaches both the Elixir language and the Phoenix framework.
  * [Elixir Cheat-Sheet](http://media.pragprog.com/titles/elixir/ElixirCheat.pdf) - A Elixir cheat sheet, by Andy Hunt & Dave Thomas.

  ## Screencasts
  *Cool video tutorials.*

  * [Alchemist Camp](https://alchemist.camp) - Alchemist.Camp has many hours of free, project-based Elixir-learning screencasts.
  * [Confreaks (Elixir)](http://confreaks.tv/tags/40) - Elixir related conference talks.

  ## Styleguides
  *Styleguides for ensuring consistency while coding.*

  * [christopheradams/elixir_style_guide](https://github.com/christopheradams/elixir_style_guide) - A community-driven style guide for Elixir.

  ## Websites
  *Useful Elixir-related websites.*

  * [30 Days of Elixir](https://github.com/seven1m/30-days-of-elixir) - A walk through the Elixir language in 30 exercises.
  * [BEAM Community](http://beamcommunity.github.io/) - From distributed systems, to robust servers and language design on the Erlang VM.

  # Contributing
  Please see [CONTRIBUTING](https://github.com/h4cc/awesome-elixir/blob/master/.github/CONTRIBUTING.md) for details.
  """

  @invalid_elixir_md """
  # Awesome Elixir [![Build Status](https://api.travis-ci.org/h4cc/awesome-elixir.svg?branch=master)](https://travis-ci.org/h4cc/awesome-elixir) [![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
  A curated list of amazingly awesome Elixir libraries, resources, and shiny things inspired by [awesome-php](https://github.com/ziadoz/awesome-php).

  If you think a package should be added, please add a :+1: (`:+1:`) at the according issue or create a new one.

  There are [other sites with curated lists of elixir packages](#other-awesome-lists) which you can have a look at.

  - [Awesome Elixir](#awesome-elixir)
      - [Actors](#actors)
      - [Algorithms and Data structures](#algorithms-and-data-structures)
  - [Resources](#resources)
      - [Books](#books)
  - [Contributing](#contributing)
  """

@parsed_project  {
  %{desc: "Libraries and tools for working with actors and such.", topic: "Actors"},
  %{
    desc: " - Pipelined flow processing engine.",
    href: "https://github.com/dalmatinerdb/dflow",
    last_commit: nil,
    name: "dflow",
    stars: nil
  }
}

  @full_parsed_project  {
    %{desc: "Libraries and tools for working with actors and such.", topic: "Actors"},
    %{
      desc: " - Pipelined flow processing engine.",
      href: "https://github.com/dalmatinerdb/dflow",
      last_commit: "2020",
      name: "dflow",
      stars: 2
    }
  }


  test "parse_markdown" do
    {:ok, store} = Hello.Parser.parse_markdown({:ok, @valid_elixir_md})
    parsed_project = Enum.find(store, &match?({%{topic: "Actors"}, _}, &1))

    assert @parsed_project = parsed_project
    assert Hello.Parser.parse_markdown({:ok, @invalid_elixir_md}) == []
    assert Hello.Parser.parse_markdown(:error) == :error
    assert Hello.Parser.parse_markdown(:not_found) == :error
  end

  test "update_store" do
    {:ok, store} = Hello.Parser.parse_markdown({:ok, @valid_elixir_md})
    new_project = %{
      desc: " - Pipelined flow processing engine.",
      href: "https://github.com/dalmatinerdb/dflow",
      last_commit: "2020",
      name: "dflow",
      stars: 1000
    }
    new_store = Hello.Parser.update_store([new_project], store)
    {_, parsed_project} = Enum.find(new_store, &match?({%{topic: "Actors"}, _}, &1))

    assert new_project = parsed_project
  end

  test "parse_git_project" do
    {:ok, project} = Hello.Parser.parse_git_project({:ok,
      """
      {
        "stargazers_count": 1000,
        "pushed_at": "2019",
        "name": "dflow",
        "description": " - Pipelined flow processing engine.",
        "html_url": "https://github.com/dalmatinerdb/dflow"
      }
      """
    })

    assert  %{
      desc: " - Pipelined flow processing engine.",
      href: "https://github.com/dalmatinerdb/dflow",
      last_commit: "2019",
      name: "dflow",
      stars: 1000
    } = project
    assert Hello.Parser.parse_git_project(:not_found) == :not_found
    assert Hello.Parser.parse_git_project(:error) == :error
    assert Hello.Parser.parse_git_project({:ok,"{\"stargazers_count\": 1000}"}) == :error
  end

  test "modify_result" do
    [res | _] = Hello.Parser.modify_result([@full_parsed_project])
    [link | _] = res.links
    assert link.stars == 2
    assert res.title == "Actors"
  end
end
