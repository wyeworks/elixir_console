defmodule ElixirConsole.Sandbox.RuntimeValidationsTest do
  use ExUnit.Case, async: true
  alias ElixirConsole.Sandbox.RuntimeValidations

  test "does not make any change to the AST when no needed" do
    command = "[1, 2, 3, 5] ++ [4, 5]"
    {:ok, original_ast} = Code.string_to_quoted(command)
    assert original_ast == RuntimeValidations.get_augmented_ast(command)
  end

  test "inserts an inline call when dot operator is used" do
    command = "Enum.count([])"

    {:ok, expected_ast} =
      Code.string_to_quoted(
        "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :count).count([])"
      )

    assert expected_ast == RuntimeValidations.get_augmented_ast(command)
  end

  test "inserts an inline call when pipe operator is used" do
    command = "[] |> Enum.count"

    {:ok, expected_ast} =
      Code.string_to_quoted(
        "[] |> ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :count).count()"
      )

    assert expected_ast == RuntimeValidations.get_augmented_ast(command)
  end

  test "inserts inline calls within nested expressions" do
    command = "Enum.count(Enum.map([1,2,3], &(&1 * 2)))"

    {:ok, expected_ast} =
      Code.string_to_quoted(
        "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :count).count(" <>
          "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :map).map([1,2,3], &(&1 * 2)))"
      )

    assert expected_ast == RuntimeValidations.get_augmented_ast(command)
  end
end
