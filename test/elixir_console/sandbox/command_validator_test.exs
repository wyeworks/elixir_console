defmodule ElixirConsole.Sandbox.CommandValidatorTest do
  use ExUnit.Case, async: true
  alias ElixirConsole.Sandbox.CommandValidator

  describe "safe_command?/1" do
    test "returns :ok when the command is valid" do
      assert :ok == CommandValidator.safe_command?("List.first([1,2,3])")
    end

    test "returns :error when using an invalid module" do
      assert {:error,
              "It is not allowed to use some Elixir modules. " <>
                "Not allowed modules attempted: [:File]"} ==
               CommandValidator.safe_command?("File.cwd()")
    end

    test "returns :error when mixing valid and invalid modules" do
      command = ~s{Enum.map(["file1", "file2"], &File.exists?(File.cwd(), &1))}

      assert {:error,
              "It is not allowed to use some Elixir modules. " <>
                "Not allowed modules attempted: [:File]"} ==
               CommandValidator.safe_command?(command)
    end

    test "returns :ok when using a valid Kernel function with implicit module" do
      assert :ok == CommandValidator.safe_command?("length([])")
    end

    test "returns :ok when using a valid Kernel function with explicit module" do
      assert :ok == CommandValidator.safe_command?("Kernel.length([])")
    end

    test "returns :error when using an invalid Kernel function" do
      assert {:error,
              "It is allowed to invoke only safe Kernel functions. " <>
                "Not allowed functions attempted: [:apply]"} ==
               CommandValidator.safe_command?("apply(Enum, :count, [[]])")
    end

    test "returns :error when using an Erlang module" do
      assert {:error,
              "It is not allowed to invoke non-Elixir modules. " <>
                "Not allowed modules attempted: [:lists]"} ==
               CommandValidator.safe_command?(":lists.last([5])")
    end
  end
end
