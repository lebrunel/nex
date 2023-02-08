defmodule Nex.Messages.EventTest do
  use Nex.TestCase
  alias Nex.Messages.Event

  setup_all do
    privkey = K256.Schnorr.generate_random_signing_key()
    {:ok, event: build_event(privkey)}
  end

  describe "changeset/2" do
    test "validates valid event", %{event: event} do
      assert %{valid?: true} = Event.changeset(event)
    end

    test "validates required fields" do
      changes = Event.changeset(%Event{})
      assert %{id: ["can't be blank"]} = errors_on(changes)
      assert %{created_at: ["can't be blank"]} = errors_on(changes)
      assert %{kind: ["can't be blank"]} = errors_on(changes)
      assert %{pubkey: ["can't be blank"]} = errors_on(changes)
      assert %{sig: ["can't be blank"]} = errors_on(changes)
    end

    test "validates kind field is positive a number", %{event: event} do
      changes = Event.changeset(event, %{kind: -100})
      assert %{kind: ["must be greater than or equal to 0"]} = errors_on(changes)
      changes = Event.changeset(event, %{kind: "not a num"})
      assert %{kind: ["is invalid"]} = errors_on(changes)
    end

    test "validates pubkey format", %{event: event} do
      changes = Event.changeset(event, %{pubkey: "not 32 bytes hex"})
      assert %{pubkey: ["has invalid format"]} = errors_on(changes)
    end

    test "validates sig format", %{event: event} do
      changes = Event.changeset(event, %{sig: "not 64 bytes hex"})
      assert %{sig: ["has invalid format"]} = errors_on(changes)
    end
  end

  describe "verify_changeset/2" do

    test "validates sig is valid", %{event: event} do
      changes = Event.verify_changeset(event, %{sig: "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"})
      assert %{sig: ["invalid signature"]} = errors_on(changes)
    end
  end

  describe "calc_id/1" do
    test "calculates and returns the id", %{event: event} do
      id = Event.calc_id(event)
      assert String.match?(id, ~r/^([a-f0-9]{2}){32}$/)
      assert id == event.id
    end
  end

  describe "id_preimage/1" do
    test "returns json string preimage data", %{event: event} do
      str = Event.id_preimage(event)
      assert {:ok, _data} = Jason.decode(str)
    end
  end
end
