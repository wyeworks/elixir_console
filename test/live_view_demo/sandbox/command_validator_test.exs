defmodule LiveViewDemo.Sandbox.CommandValidatorTest do
  use ExUnit.Case
  alias LiveViewDemo.Sandbox.CommandValidator

  describe "safe_command?/1" do
    test "returns :ok when the command is valid" do
      assert :ok == CommandValidator.safe_command?("List.first([1,2,3])")
    end

    test "returns :error when using an invalid module" do
      assert {:error, "Invalid modules: [:File]"} ==
               CommandValidator.safe_command?("File.cwd()")
    end

    test "returns :error when mixing valid and invalid modules" do
      command = ~s{Enum.map(["file1", "file2"], &File.exists?(File.cwd(), &1))}

      assert {:error, "Invalid modules: [:File]"} == CommandValidator.safe_command?(command)
    end

    test "returns :error when using defmodule" do
      assert {:error, "Defining new modules is not allowed. Do not use `defmodule`."} ==
               CommandValidator.safe_command?("defmodule Test, do: nil")
    end
  end
end
