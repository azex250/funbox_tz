defmodule Hello.AsyncUtilsTest do
  use ExUnit.Case
  doctest Hello.AsyncUtils

  test "async_test" do
    task = fn a ->
      :timer.sleep(1000)
      a + 1
    end

    {duration, res} = :timer.tc(&Hello.AsyncUtils.process/2 ,[1..10, task])
    assert (duration / 1_000_000) < 2
    assert [2, 3, 4, 5, 6, 7, 8, 9, 10, 11] = res
  end
end
