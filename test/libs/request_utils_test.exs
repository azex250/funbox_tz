defmodule Hello.RequestUtilsTest do
  use ExUnit.Case
  doctest Hello.RequestUtils
  import Mock

  @valid_response %HTTPoison.Response{
    status_code: 200,
    headers: [{"content-type", "application/json"}],
    body: "{\"hello\": 2020}"
  }

  @not_found_response %HTTPoison.Response{
    status_code: 404,
    headers: [{"content-type", "application/json"}],
    body: "{}"
  }

  @redirect_response %HTTPoison.Response{
    status_code: 301,
    headers: [{"Location", "http://valid.ru"}],
    body: "{}"
  }

  @error_response %HTTPoison.Response{
    status_code: 500,
    headers: [],
    body: "{}"
  }

  test "simple_request" do
    with_mock HTTPoison, [get: fn(_url, _headers) -> {:ok, @valid_response} end] do
      assert {:ok, @valid_response.body} == Hello.RequestUtils.request("http://example.com")
    end
  end

  test "not_found_request" do
    with_mock HTTPoison, [get: fn(_url, _headers) -> {:ok, @not_found_response} end] do
      assert :not_found == Hello.RequestUtils.request("http://example.com")
    end
  end

  test "redirect_request" do
    with_mock HTTPoison, [ get: fn
      ("http://example.com", _headers) -> {:ok, @redirect_response}
      ("http://valid.ru", _headers) -> {:ok, @valid_response}
    end] do
      assert {:ok, @valid_response.body} == Hello.RequestUtils.request("http://example.com")
    end
  end

  test "error_response" do
    with_mock HTTPoison, [get: fn(_url, _headers) -> {:ok, @error_response} end] do
      assert :error == Hello.RequestUtils.request("http://example.com")
    end
  end
end
