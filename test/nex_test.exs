defmodule NexTest do
  use Nex.TestCase

  describe "relay_info/1" do
    test "returns a map with default values" do
      assert %{} = info = Nex.relay_info()
      refute Map.has_key?(info, :name)
      assert is_list(info.supported_nips)
      assert is_binary(info.software)
      assert is_binary(info.version)
    end

    test "returns a map with custom values and ignores unsopprted values" do
      assert %{} = info = Nex.relay_info(%{name: "test", test: "test"})
      assert info.name == "test"
      refute Map.has_key?(info, :test)
      assert is_binary(info.software)
    end
  end

end
