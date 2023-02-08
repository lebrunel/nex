defmodule Nex.Nips.Nip01Test do
  use Nex.TestCase
  use Plug.Test
  import Ecto.Query, only: [from: 2]
  alias Nex.Messages.Event

  setup_all do
    alys_key = K256.Schnorr.generate_random_signing_key()
    bob_key = K256.Schnorr.generate_random_signing_key()
    {:ok, alys: alys_key, bob: bob_key}
  end

  describe "Creating events [NIP-01]" do
    test "posting a valid event stores it in the db", %{alys: alys_key} do
      assert Nex.Repo.aggregate(Event, :count, :id) == 0

      # Alys connects and posts an message
      assert {:ok, {%{socket: port}, _, _} = ws} = ws_connect()
      %{id: id} = msg = build_event(%{content: "alys test"}, alys_key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", msg])})

      # Recieve a success msg back
      assert_receive {:tcp, ^port, _} = success_message
      assert {:ok, ws, [{:text, res}]} = ws_decode(ws, success_message)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      ws_close(ws)
      assert Nex.Repo.aggregate(Event, :count, :id) == 1
    end

    test "posting invalid event recieves error", %{alys: alys_key} do
      assert Nex.Repo.aggregate(Event, :count, :id) == 0

      # Alys connects and posts an invalid message
      assert {:ok, {%{socket: port}, _, _} = ws} = ws_connect()
      %{id: id} = msg = build_event(alys_key) |> Map.put(:content, "alys test")
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", msg])})

      # Recieve a success msg back
      assert_receive {:tcp, ^port, _} = success_message
      assert {:ok, ws, [{:text, res}]} = ws_decode(ws, success_message)
      assert ["OK", ^id, false, "invalid:" <> _] = Jason.decode!(res)

      ws_close(ws)
      assert Nex.Repo.aggregate(Event, :count, :id) == 0
    end

    test "posting metadata deletes previous metadata", %{alys: alys_key} do
      %{nid: nid} = create(build_event(%{kind: 0, content: "alys 1"}, alys_key))
      assert Nex.Repo.aggregate(Event, :count, :id) == 1

      # Alys connects and posts a new metadata
      assert {:ok, {%{socket: port}, _, _} = ws} = ws_connect()
      %{id: id} = msg = build_event(%{kind: 0, content: "alys 2"}, alys_key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", msg])})

      # Recieve a success msg back
      assert_receive {:tcp, ^port, _} = success_message
      assert {:ok, ws, [{:text, res}]} = ws_decode(ws, success_message)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      ws_close(ws)
      assert Nex.Repo.aggregate(Event, :count, :id) == 1
      assert Nex.Repo.one(from e in Event, where: e.nid == ^nid) == nil
    end
  end

  describe "Creating subscriptions [NIP-01]" do
    setup ctx do
      alys_pub =
        K256.Schnorr.verifying_key_from_signing_key(ctx.alys)
        |> elem(1)
        |> Base.encode16(case: :lower)

      Map.put(ctx, :alys_pub, alys_pub)
    end

    test "subscribing to alys pubkey responds with her current events", %{alys: alys_key, alys_pub: alys_pub} do
      for i <- 1..3, do: create(build_event(%{content: "alys #{i}"}, alys_key))

      # Bob connects and subscribes to Alys's feed
      assert {:ok, {%{socket: port}, _, _} = ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["REQ", "abc", %{"authors" => [alys_pub]}])})

      # Recieve the event messages
      assert_receive {:tcp, ^port, _} = event_messages
      assert {:ok, ws, events} = ws_decode(ws, event_messages)
      assert length(events) == 4

      ws_close(ws)
    end

    test "subscribing to alys pubkey responds with her future events", %{alys: alys_key, alys_pub: alys_pub} do
      # Bob connects and subscribes to Alys's feed
      sub_id = "abc"
      assert {:ok, {%{socket: bob_port}, _, _} = bob_ws} = ws_connect()
      assert {:ok, bob_ws} = ws_push(bob_ws, {:text, Jason.encode!(["REQ", sub_id, %{"authors" => [alys_pub]}])})

      # Bob recieves initial EOSE message
      assert_receive {:tcp, ^bob_port, _} = event_message
      assert {:ok, bob_ws, [{:text, res}]} = ws_decode(bob_ws, event_message)
      assert ["EOSE", ^sub_id] = Jason.decode!(res)

      # Alys connects and posts an message
      assert {:ok, {%{socket: alys_port}, _, _} = alys_ws} = ws_connect()
      %{id: id} = msg = build_event(%{content: "alys test"}, alys_key)
      assert {:ok, alys_ws} = ws_push(alys_ws, {:text, Jason.encode!(["EVENT", msg])})

      # Alys recieve a success msg back
      assert_receive {:tcp, ^alys_port, _} = success_message
      assert {:ok, alys_ws, [{:text, res}]} = ws_decode(alys_ws, success_message)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      # Bob recieves the event message
      assert_receive {:tcp, ^bob_port, _} = event_message
      assert {:ok, bob_ws, [{:text, event}]} = ws_decode(bob_ws, event_message)
      assert ["EVENT", ^sub_id, _msg] = Jason.decode!(event)

      ws_close(alys_ws)
      ws_close(bob_ws)
    end

    test "invalid subscription returns an error notice" do
      sub_id = "abc"
      assert {:ok, {%{socket: port}, _, _} = ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["REQ", sub_id, %{}, %{}])})

      # Recieves a notice msg back
      assert_receive {:tcp, ^port, _} = notice_message
      assert {:ok, ws, [{:text, res}]} = ws_decode(ws, notice_message)
      assert ["NOTICE", msg] = Jason.decode!(res)
      assert String.match?(msg, ~r/invalid/)

      ws_close(ws)
    end

    test "duplicate subscription returns an error notice" do
      sub_id = "abc"
      assert {:ok, {%{socket: port}, _, _} = ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["REQ", sub_id, %{"authors" => ["abc"]}])})

      # Recieves initial EOSE msg
      assert_receive {:tcp, ^port, _} = notice_message
      assert {:ok, ws, [{:text, res}]} = ws_decode(ws, notice_message)
      assert ["EOSE", ^sub_id] = Jason.decode!(res)

      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["REQ", sub_id, %{"authors" => ["abc"]}])})

      # Recieves a notice msg back
      assert_receive {:tcp, ^port, _} = notice_message
      assert {:ok, ws, [{:text, res}]} = ws_decode(ws, notice_message)
      assert ["NOTICE", msg] = Jason.decode!(res)
      assert String.match?(msg, ~r/duplicate/)

      ws_close(ws)
    end
  end

end
