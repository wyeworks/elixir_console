defmodule ElixirConsole.Sandbox.RuntimeValidationsTest do
  use ExUnit.Case, async: true
  alias ElixirConsole.Sandbox.RuntimeValidations

  test "does not make any change to the AST when no needed" do
    command = "[1, 2, 3, 5] ++ [4, 5]"
    {:ok, original_ast} = Code.string_to_quoted(command)
    assert original_ast == RuntimeValidations.get_augmented_ast(command)
  end

  test "replaces invocation when dot operator is used" do
    command = "Enum.count([2])"

    {:ok, expected_ast} =
      Code.string_to_quoted(
        "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :count, [[2]])"
      )

    assert expected_ast == RuntimeValidations.get_augmented_ast(command)
  end

  test "replace invocations within nested expressions" do
    command = "Enum.count(Enum.map([1,2,3], &(&1 * 2)))"

    {:ok, expected_ast} =
      Code.string_to_quoted(
        "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :count, [" <>
          "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :map, [[1,2,3], &(&1 * 2)])" <>
          "])"
      )

    assert expected_ast == RuntimeValidations.get_augmented_ast(command)
  end

  test "changes to direct invocation and replaces invocation when pipe operator is used" do
    command = "[1,2,3] |> Enum.map(fn n -> n * 2 end) |> Enum.count"

    {:ok, expected_ast} =
      Code.string_to_quoted(
        "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :count, [" <>
          "ElixirConsole.Sandbox.RuntimeValidations.safe_invocation(Enum, :map, [[1,2,3], fn n -> n * 2 end])" <>
          "])"
      )

    assert expected_ast == RuntimeValidations.get_augmented_ast(command)
  end

  test "makes a safe invocation when string interpolation is used" do
    command = "\"Hello \#{:world}\""

    expected_ast =
      {:<<>>, [line: 1],
       [
         "Hello ",
         {:"::", [line: 1],
          [
            {{:., [line: 1],
              [
                {:__aliases__, [line: 1], [:ElixirConsole, :Sandbox, :RuntimeValidations]},
                :safe_invocation
              ]}, [line: 1], [Kernel, :to_string, [:world]]},
            {:binary, [line: 1], nil}
          ]}
       ]}

    assert expected_ast == RuntimeValidations.get_augmented_ast(command)
  end
end
