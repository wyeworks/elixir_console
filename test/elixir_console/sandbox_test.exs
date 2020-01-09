defmodule ElixirConsole.SandboxTest do
  use ExUnit.Case, async: true
  alias ElixirConsole.Sandbox

  setup do
    [sandbox: Sandbox.init()]
  end

  describe "Sandbox success and error cases" do
    test "runs a basic command", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: []}

      assert Sandbox.execute("1 + 2", sandbox) == {:success, {3, expected_sandbox}}
    end

    test "adds a new binding", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: [a: 3]}

      assert Sandbox.execute("a = 1 + 2", sandbox) == {:success, {3, expected_sandbox}}
    end

    test "updates an existing binding", %{sandbox: sandbox} do
      sandbox = %Sandbox{sandbox | bindings: [a: "foo"]}
      expected_sandbox = %Sandbox{sandbox | bindings: [a: 3]}

      assert Sandbox.execute("a = 1 + 2", sandbox) == {:success, {3, expected_sandbox}}
    end

    test "keeps existing bindings", %{sandbox: sandbox} do
      sandbox = %Sandbox{sandbox | bindings: [a: "foo"]}
      expected_sandbox = %Sandbox{sandbox | bindings: [a: "foo"]}

      assert Sandbox.execute("1 + 2", sandbox) == {:success, {3, expected_sandbox}}
    end

    test "reports excessive memory usage", %{sandbox: sandbox} do
      assert {:error, {"The command used more memory than allowed", _}} =
               Sandbox.execute("for i <- 1..70_000, do: i", sandbox)
    end

    test "reports excessive memory usage with custom memory limit", %{sandbox: sandbox} do
      assert {:error, {"The command used more memory than allowed", _}} =
               Sandbox.execute("for i <- 1..100_000_000, do: i", sandbox, max_memory_kb: 10)
    end

    test "reports excessive time spent on the execution", %{sandbox: sandbox} do
      assert {:error, {"The command was cancelled due to timeout", _}} =
               Sandbox.execute("Enum.each(1..100_000_000, &(&1))", sandbox, timeout: 50)
    end

    test "refuses to run unsafe code", %{sandbox: sandbox} do
      assert {:error,
              {"It is not allowed to use some Elixir modules. " <>
                 "Not allowed modules attempted: [:File]",
               _}} = Sandbox.execute("File.cwd()", sandbox)
    end

    test "refuses to run a very large command", %{sandbox: sandbox} do
      assert {:error, {"Command is too long. Try running a shorter piece of code.", _}} =
               Sandbox.execute(
                 String.duplicate("a", 600),
                 sandbox
               )
    end

    test "allows to run more commands after excessive memory usage error", %{sandbox: sandbox} do
      {:error, {_, sandbox}} = Sandbox.execute("for i <- 1..70_000, do: i", sandbox)

      assert {:success, {3, _}} = Sandbox.execute("1 + 2", sandbox)
    end

    test "allows to run more commands after timeout error", %{sandbox: sandbox} do
      {:error, {_, sandbox}} = Sandbox.execute(":timer.sleep(100)", sandbox, timeout: 50)

      assert {:success, {3, _}} = Sandbox.execute("1 + 2", sandbox)
    end

    test "returns a runtime error when about to invoke an unsafe function", %{sandbox: sandbox} do
      assert {:error,
              {"%RuntimeError{message: \"Sandbox runtime error: " <>
                 "It is not allowed to use some Elixir modules. " <>
                 "Not allowed module attempted: File\"}",
               _}} = Sandbox.execute(":\"Elixir.File\".cwd()", sandbox)
    end
  end

  describe "Elixir functionality that is supported by the console" do
    test "works with string interpolation", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: []}

      assert Sandbox.execute("\"Hello \#{:world}\"", sandbox) ==
               {:success, {"Hello world", expected_sandbox}}
    end

    test "works with pipe operator", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: []}

      assert Sandbox.execute("[1,2,3] |> Enum.filter(fn n -> n > 2 end) |> Enum.count", sandbox) ==
               {:success, {1, expected_sandbox}}
    end

    test "works with tuples in pattern matching", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: [a: :hello, b: "world", c: 42]}

      assert Sandbox.execute("{a, b, c} = {:hello, \"world\", 42}", sandbox) ==
               {:success, {{:hello, "world", 42}, expected_sandbox}}
    end

    test "works with list in pattern matching", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: [head: 1, tail: [2, 3]]}

      assert Sandbox.execute("[head | tail] = [1, 2, 3]", sandbox) ==
               {:success, {[1, 2, 3], expected_sandbox}}
    end

    test "works with basic if blocks", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: []}

      assert Sandbox.execute("if true, do: :great", sandbox) ==
               {:success, {:great, expected_sandbox}}

      assert Sandbox.execute("if false, do: :great, else: :bad", sandbox) ==
               {:success, {:bad, expected_sandbox}}
    end

    test "works with Bitwise macros (without the need to use the module)", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: []}

      assert Sandbox.execute("1 &&& 1", sandbox) ==
               {:success, {1, expected_sandbox}}
    end

    test "works with improper lists", %{sandbox: sandbox} do
      expected_sandbox = %Sandbox{sandbox | bindings: [a: [1, 2 | 3], b: [4 | 5]]}

      assert Sandbox.execute("{a, b} = {[1, 2] ++ 3, [4 | 5]}", sandbox) ==
               {:success, {{[1, 2 | 3], [4 | 5]}, expected_sandbox}}
    end
  end
end
