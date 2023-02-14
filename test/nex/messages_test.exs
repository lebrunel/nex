defmodule Nex.MessagesTest do
  use Nex.TestCase
  alias Nex.Messages
  alias Nex.Messages.Filter

  setup_all do
    k1 = K256.Schnorr.generate_random_signing_key()
    k2 = K256.Schnorr.generate_random_signing_key()
    k3 = K256.Schnorr.generate_random_signing_key()
    {:ok, k1: k1, k2: k2, k3: k3}
  end

  setup ctx do
    tags1 = [["x", "xxx"]]
    tags4 = [["a", "a", "b", "c"], ["b", "bbb"]]
    tags5 = [["b", "bbb"]]
    e1 = create(build_event(%{kind: 1, content: "t1", tags: tags1, created_at: 1675100000}, ctx.k1))
    e2 = create(build_event(%{kind: 101, content: "t2", created_at: 1675200000}, ctx.k2))
    e3 = create(build_event(%{kind: 102, content: "t3", created_at: 1675300000}, ctx.k3))
    e4 = create(build_event(%{kind: 102, content: "t4", tags: tags4, created_at: 1675400000}, ctx.k3))
    e5 = create(build_event(%{kind: 102, content: "t5", tags: tags5, created_at: 1675500000}, ctx.k3))
    {:ok, e1: e1, e2: e2, e3: e3, e4: e4, e5: e5}
  end

  describe "list_events/1 with single filter" do
    test "filters by any id", ctx do
      res =
        [%{"ids" => [ctx.e1.id, ctx.e2.id, "xxxx", "yyyy"]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 2
      assert Enum.find(res, & &1.id == ctx.e1.id)
      assert Enum.find(res, & &1.id == ctx.e2.id)
    end

    test "filters by any id prefix", ctx do
      assert [res] =
        [%{"ids" => [String.slice(ctx.e1.id, 0..24)]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert res.id == ctx.e1.id
    end

    test "filters by any pubkey", ctx do
      pk1 = K256.Schnorr.verifying_key_from_signing_key(ctx.k1) |> elem(1) |> Base.encode16(case: :lower)
      pk2 = K256.Schnorr.verifying_key_from_signing_key(ctx.k2) |> elem(1) |> Base.encode16(case: :lower)

      res =
        [%{"authors" => [pk1, pk2, "xxxx", "yyyy"]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 2
      assert Enum.find(res, & &1.id == ctx.e1.id)
      assert Enum.find(res, & &1.id == ctx.e2.id)
    end

    test "filters by any pubkey prefix", ctx do
      pk1 = K256.Schnorr.verifying_key_from_signing_key(ctx.k1) |> elem(1) |> Base.encode16(case: :lower)

      assert [res] =
        [%{"authors" => [String.slice(pk1, 0..24)]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert res.id == ctx.e1.id
    end

    test "filters by any kind", ctx do
      res =
        [%{"kinds" => [1, 101, 998, 999]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 2
      assert Enum.find(res, & &1.id == ctx.e1.id)
      assert Enum.find(res, & &1.id == ctx.e2.id)
    end

    test "filters since created at", ctx do
      res =
        [%{"since" => 1675150000}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 4
      assert Enum.find(res, & &1.id == ctx.e2.id)
      assert Enum.find(res, & &1.id == ctx.e3.id)
    end

    test "filters until created at", ctx do
      assert [res] =
        [%{"until" => 1675150000}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert res.id == ctx.e1.id
    end

    test "filters by any individual tag", ctx do
      assert res =
        [%{"#b" => ["bbb", "yyy", "zzz"]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 2
      assert Enum.find(res, & &1.id == ctx.e4.id)
      assert Enum.find(res, & &1.id == ctx.e5.id)
    end

    test "filters by combo tags", ctx do
      assert [res] =
        [%{"#a" => ["a"], "#b" => ["bbb"]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert res.id == ctx.e4.id
    end

    test "multiple fields in same filter are AND queries", ctx do
      assert res1 =
        [%{"since" => 1675100000}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert res2 =
        [%{"since" => 1675100000, "kinds" => [102]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert res3 =
        [%{"since" => 1675100000, "kinds" => [102], "#b" => ["bbb"]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert [res4] =
        [%{"since" => 1675100000, "kinds" => [102], "limit" => 1}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res1) == 5
      assert length(res2) == 3
      assert length(res3) == 2
      assert res4.id == ctx.e5.id
    end
  end

  describe "list_events/1 with multiple filters" do
    test "seperate date filters are OR queries", ctx do
      assert res =
        [%{"until" => 1675100000}, %{"since" => 1675500000}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 2
      assert Enum.find(res, & &1.id == ctx.e1.id)
      assert Enum.find(res, & &1.id == ctx.e5.id)
    end

    test "returns distinct events only", ctx do
      assert res =
        [%{"until" => 1675100000}, %{"since" => 1675500000}, %{"ids" => [ctx.e1.id]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 2
      assert Enum.find(res, & &1.id == ctx.e1.id)
      assert Enum.find(res, & &1.id == ctx.e5.id)
    end

    test "separate tag filters are OR queries", ctx do
      assert res =
        [%{"#b" => ["bbb", "yyy", "zzz"]}, %{"#x" => ["xxx"]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 3
      assert Enum.find(res, & &1.id == ctx.e1.id)
      assert Enum.find(res, & &1.id == ctx.e4.id)
      assert Enum.find(res, & &1.id == ctx.e5.id)
    end

    test "combo tag and kinds filters are OR queries", ctx do
      assert res =
        [%{"#b" => ["bbb", "yyy", "zzz"]}, %{"#x" => ["xxx"]}, %{"kinds" => [102]}]
        |> Enum.map(&Filter.cast/1)
        |> Messages.list_events()

      assert length(res) == 4
      assert Enum.find(res, & &1.id == ctx.e1.id)
      assert Enum.find(res, & &1.id == ctx.e3.id)
      assert Enum.find(res, & &1.id == ctx.e4.id)
      assert Enum.find(res, & &1.id == ctx.e5.id)
    end
  end

end
