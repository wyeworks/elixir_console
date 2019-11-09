defmodule LiveViewDemo.WhiteListTest do
  use ExUnit.Case
  alias LiveViewDemo.WhiteList

  describe "validate/2" do
    test "returns :ok when the command is valid" do
      command = "List.first([1,2,3])"
      expected_result = {:ok, command}

      assert WhiteList.validate(command) == expected_result
    end

    test "returns :error when using an invalid module" do
      command = "File.cwd()"
      expected_result = {:error, "Invalid modules: [:File]"}

      assert WhiteList.validate(command) == expected_result
    end

    test "returns :error when mixing valid and invalid modules" do
      command = ~s{Enum.map(["file1", "file2"], &File.exists?(File.cwd(), &1))}
      expected_result = {:error, "Invalid modules: [:File]"}

      assert WhiteList.validate(command) == expected_result
    end
  end
end
