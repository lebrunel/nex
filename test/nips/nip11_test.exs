defmodule Nex.Nips.Nip11Test do
  use Nex.TestCase
  use Plug.Test

  describe "GET / [NIP-11]" do
    test "returns relay info doc with correct header" do
      assert {200, _headers, body} = conn(:GET, "/")
      |> Plug.Conn.put_req_header("accept", "application/nostr+json")
      |> Nex.Plug.call(Nex.Plug.init([]))
      |> sent_resp()

      assert {:ok, relay_info} = Jason.decode(body)
      assert Map.has_key?(relay_info, "software")
      assert Map.has_key?(relay_info, "supported_nips")
      assert Map.has_key?(relay_info, "version")
    end

    test "returns html page without header" do
      assert {200, _headers, body} = conn(:GET, "/")
      |> Nex.Plug.call(Nex.Plug.init([]))
      |> sent_resp()

      assert String.match?(body, ~r/nex/)
    end
  end

end
