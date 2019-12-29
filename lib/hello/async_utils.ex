defmodule Hello.AsyncUtils do
  def process(items, f, acc\\[], parallelism\\25) do
    run = fn
      item -> Task.async(fn -> f.(item) end)
    end

    case items do
      [] -> acc
      _ ->
      {h, t} = Enum.split(items, parallelism)
      res = Enum.map(h, run) |> Enum.map(&Task.await/1)
      process(t, f, acc ++ res, parallelism)
    end
  end
end
