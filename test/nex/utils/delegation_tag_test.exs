defmodule Nex.Utils.DelegatedEventsTest do
  use Nex.TestCase
  alias Nex.Messages.{Event, Tag}
  alias Nex.Utils.DelegatedEvents

  setup_all do
    privkey = K256.Schnorr.generate_random_signing_key()
    params = %{
      "id" => "a080fd288b60ac2225ff2e2d815291bd730911e583e177302cc949a15dc2b2dc",
      "pubkey" => "62903b1ff41559daf9ee98ef1ae67cc52f301bb5ce26d14baba3052f649c3f49",
      "created_at" => 1660896109,
      "kind" => 1,
      "tags" => [
        [
          "delegation",
          "86f0689bd48dcd19c67a19d994f938ee34f251d8c39976290955ff585f2db42e",
          "kind=1&created_at>1640995200",
          "c33c88ba78ec3c760e49db591ac5f7b129e3887c8af7729795e85a0588007e5ac89b46549232d8f918eefd73e726cb450135314bfda419c030d0b6affe401ec1",
        ],
      ],
      "content" => "Hello world",
      "sig" => "cd4a3cd20dc61dcbc98324de561a07fd23b3d9702115920c0814b5fb822cc5b7c5bcdaf3fa326d24ed50c5b9c8214d66c75bae34e3a84c25e4d122afccb66eb6",
    }
    event = Event.changeset(%Event{}, params) |> Ecto.Changeset.apply_changes()
    {:ok, event: event, privkey: privkey}
  end

  describe "delegated_event?/1" do
    test "returns true when contains delegation tag", ctx do
      assert DelegatedEvents.delegated_event?(ctx.event)
    end

    test "returns false when contains no delegation tag", ctx do
      refute DelegatedEvents.delegated_event?(build_event(ctx.privkey))
    end
  end

  describe "valid_delegated_event?/2" do
    setup ctx do
      tag = Tag.find_by_name(ctx.event.tags, "delegation")
      {:ok, tag: tag}
    end

    test "returns true for valid delegation", ctx do
      assert DelegatedEvents.valid_delegated_event?(ctx.event)
    end

    test "returns false when contains no delegation tag", ctx do
      refute DelegatedEvents.valid_delegated_event?(build_event(ctx.privkey))
    end

    test "returns false if conditions do not match", ctx do
      tag = List.replace_at(ctx.tag, 2, "kind=100")
      refute DelegatedEvents.valid_delegated_event?(ctx.event, tag)
    end

    test "returns false if signature is invalid", ctx do
      sig = :crypto.strong_rand_bytes(64) |> Base.encode16(case: :lower)
      tag = List.replace_at(ctx.tag, 3, sig)
      refute DelegatedEvents.valid_delegated_event?(ctx.event, tag)
    end
  end

end
