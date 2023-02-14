defmodule Nex.Messages.DBTagTest do
  use Nex.TestCase
  alias Nex.Messages.DBTag

  setup_all do
    {:ok, tag: build_tag()}
  end

  describe "changeset/2" do
    test "validates valid tag", %{tag: tag} do
      assert %{valid?: true} = DBTag.changeset(tag)
    end

    test "validates required fields" do
      changes = DBTag.changeset(%DBTag{})
      assert %{name: ["can't be blank"]} = errors_on(changes)
    end

    test "accepts valid values" do
      assert %{valid?: true} = DBTag.changeset(%DBTag{}, %{name: "x", value: "xyz"})
    end
  end
end
