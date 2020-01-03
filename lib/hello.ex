defmodule Hello do
  @moduledoc """
  Hello keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @type projects_store :: [%{
     title: String.t,
     desc: String.t,
     links: [%{
       desc:  String.t,
       href:  String.t,
       last_commit:  String.t,
       name:  String.t,
       stars: integer
     }]
  }]
end
