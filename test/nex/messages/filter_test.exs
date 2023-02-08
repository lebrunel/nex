defmodule Nex.Messages.FilterTest do
  use Nex.TestCase
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
    e1 = build_event(%{kind: 1, content: "t1", tags: tags1, created_at: 1675100000}, ctx.k1)
    e2 = build_event(%{kind: 101, content: "t2", created_at: 1675200000}, ctx.k2)
    e3 = build_event(%{kind: 102, content: "t3", created_at: 1675300000}, ctx.k3)
    e4 = build_event(%{kind: 102, content: "t4", tags: tags4, created_at: 1675400000}, ctx.k3)
    e5 = build_event(%{kind: 102, content: "t5", tags: tags5, created_at: 1675500000}, ctx.k3)
    {:ok, e1: e1, e2: e2, e3: e3, e4: e4, e5: e5}
  end

  describe "match_any?/2" do
    test "seperate date filters are OR queries", ctx do
      f =
        [%{"until" => 1675100000}, %{"since" => 1675500000}]
        |> Enum.map(&Filter.cast/1)

      assert Filter.match_any?(f, ctx.e1)
      refute Filter.match_any?(f, ctx.e2)
      refute Filter.match_any?(f, ctx.e3)
      refute Filter.match_any?(f, ctx.e4)
      assert Filter.match_any?(f, ctx.e5)
    end

    test "separate tag filters are OR queries", ctx do
      f =
        [%{"#b" => ["bbb", "yyy", "zzz"]}, %{"#x" => ["xxx"]}]
        |> Enum.map(&Filter.cast/1)

      assert Filter.match_any?(f, ctx.e1)
      refute Filter.match_any?(f, ctx.e2)
      refute Filter.match_any?(f, ctx.e3)
      assert Filter.match_any?(f, ctx.e4)
      assert Filter.match_any?(f, ctx.e5)
    end

    test "combo tag and kinds filters are OR queries", ctx do
      f =
        [%{"#b" => ["bbb", "yyy", "zzz"]}, %{"#x" => ["xxx"]}, %{"kinds" => [102]}]
        |> Enum.map(&Filter.cast/1)

      assert Filter.match_any?(f, ctx.e1)
      refute Filter.match_any?(f, ctx.e2)
      assert Filter.match_any?(f, ctx.e3)
      assert Filter.match_any?(f, ctx.e4)
      assert Filter.match_any?(f, ctx.e5)
    end
  end

  describe "match_event?/2" do
    test "filters by any id", ctx do
      f = Filter.cast(%{"ids" => [ctx.e1.id, ctx.e2.id, "xxxx", "yyyy"]})
      assert Filter.match_event?(f, ctx.e1)
      assert Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      refute Filter.match_event?(f, ctx.e4)
      refute Filter.match_event?(f, ctx.e5)
    end

    test "filters by any id prefix", ctx do
      f = Filter.cast(%{"ids" => [String.slice(ctx.e1.id, 0..24)]})
      assert Filter.match_event?(f, ctx.e1)
      refute Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      refute Filter.match_event?(f, ctx.e4)
      refute Filter.match_event?(f, ctx.e5)
    end

    test "filters by any pubkey", ctx do
      pk1 = K256.Schnorr.verifying_key_from_signing_key(ctx.k1) |> elem(1) |> Base.encode16(case: :lower)
      pk2 = K256.Schnorr.verifying_key_from_signing_key(ctx.k2) |> elem(1) |> Base.encode16(case: :lower)
      f = Filter.cast(%{"authors" => [pk1, pk2, "xxxx", "yyyy"]})
      assert Filter.match_event?(f, ctx.e1)
      assert Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      refute Filter.match_event?(f, ctx.e4)
      refute Filter.match_event?(f, ctx.e5)
    end

    test "filters by any pubkey prefix", ctx do
      pk1 = K256.Schnorr.verifying_key_from_signing_key(ctx.k1) |> elem(1) |> Base.encode16(case: :lower)
      f = Filter.cast(%{"authors" => [String.slice(pk1, 0..24)]})
      assert Filter.match_event?(f, ctx.e1)
      refute Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      refute Filter.match_event?(f, ctx.e4)
      refute Filter.match_event?(f, ctx.e5)
    end

    test "filters by any kind", ctx do
      f = Filter.cast(%{"kinds" => [1, 101, 998, 999]})
      assert Filter.match_event?(f, ctx.e1)
      assert Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      refute Filter.match_event?(f, ctx.e4)
      refute Filter.match_event?(f, ctx.e5)
    end

    test "filters since created at", ctx do
      f = Filter.cast(%{"since" => 1675150000})
      refute Filter.match_event?(f, ctx.e1)
      assert Filter.match_event?(f, ctx.e2)
      assert Filter.match_event?(f, ctx.e3)
      assert Filter.match_event?(f, ctx.e4)
      assert Filter.match_event?(f, ctx.e5)
    end

    test "filters until created at", ctx do
      f = Filter.cast(%{"until" => 1675150000})
      assert Filter.match_event?(f, ctx.e1)
      refute Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      refute Filter.match_event?(f, ctx.e4)
      refute Filter.match_event?(f, ctx.e5)
    end

    test "filters by any individual tag", ctx do
      f = Filter.cast(%{"#b" => ["bbb", "yyy", "zzz"]})
      refute Filter.match_event?(f, ctx.e1)
      refute Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      assert Filter.match_event?(f, ctx.e4)
      assert Filter.match_event?(f, ctx.e5)
    end

    test "filters by combo tags", ctx do
      f = Filter.cast(%{"#a" => ["a"], "#b" => ["bbb"]})
      refute Filter.match_event?(f, ctx.e1)
      refute Filter.match_event?(f, ctx.e2)
      refute Filter.match_event?(f, ctx.e3)
      assert Filter.match_event?(f, ctx.e4)
      refute Filter.match_event?(f, ctx.e5)
    end

    test "multiple fields in same filter are AND queries", ctx do
      events = [ctx.e1, ctx.e2, ctx.e3, ctx.e4, ctx.e5]
      f1 = Filter.cast(%{"since" => 1675100000})
      f2 = Filter.cast(%{"since" => 1675100000, "kinds" => [102]})
      f3 = Filter.cast(%{"since" => 1675100000, "kinds" => [102], "#b" => ["bbb"]})

      assert Enum.filter(events, & Filter.match_event?(f1, &1)) |> length() == 5
      assert Enum.filter(events, & Filter.match_event?(f2, &1)) |> length() == 3
      assert Enum.filter(events, & Filter.match_event?(f3, &1)) |> length() == 2
    end
  end

end
