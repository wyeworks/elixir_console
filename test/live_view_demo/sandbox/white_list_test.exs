defmodule LiveViewDemo.Sandbox.WhiteListTest do
  use ExUnit.Case
  alias LiveViewDemo.Sandbox.WhiteList

  describe "validate/2" do
    test "returns :ok when the command is valid" do
      assert {:ok, "List.first([1,2,3])"} ==
               WhiteList.validate("List.first([1,2,3])")
    end

    test "returns :error when using an invalid module" do
      assert {:error, "Invalid modules: [:File]"} ==
               WhiteList.validate("File.cwd()")
    end

    test "returns :error when mixing valid and invalid modules" do
      command = ~s{Enum.map(["file1", "file2"], &File.exists?(File.cwd(), &1))}

      assert {:error, "Invalid modules: [:File]"} ==
               WhiteList.validate(command)
    end
  end
end
