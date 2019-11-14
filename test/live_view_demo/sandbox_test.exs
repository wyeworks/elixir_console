defmodule LiveViewDemo.SandboxTest do
  use ExUnit.Case
  alias LiveViewDemo.Sandbox

  setup do
    [sandbox: Sandbox.init()]
  end

  test "runs a basic command", %{sandbox: sandbox} do
    expected_sandbox = %Sandbox{sandbox | bindings: []}

    assert Sandbox.execute("1 + 2", sandbox) == {:success, {3, expected_sandbox}}
  end

  test "adds a new binding", %{sandbox: sandbox} do
    expected_sandbox = %Sandbox{sandbox | bindings: [{"a", 3}]}

    assert Sandbox.execute("a = 1 + 2", sandbox) == {:success, {3, expected_sandbox}}
  end

  test "updates an existing binding", %{sandbox: sandbox} do
    sandbox = %Sandbox{sandbox | bindings: [{"a", "foo"}]}
    expected_sandbox = %Sandbox{sandbox | bindings: [{"a", 3}]}

    assert Sandbox.execute("a = 1 + 2", sandbox) == {:success, {3, expected_sandbox}}
  end

  test "keeps existing bindings", %{sandbox: sandbox} do
    sandbox = %Sandbox{sandbox | bindings: [{"a", "foo"}]}
    expected_sandbox = %Sandbox{sandbox | bindings: [{"a", "foo"}]}

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

  test "allows to run more commands after excessive memory usage error", %{sandbox: sandbox} do
    {:error, {_, sandbox}} = Sandbox.execute("for i <- 1..70_000, do: i", sandbox)

    assert {:success, {3, _}} = Sandbox.execute("1 + 2", sandbox)
  end

  test "allows to run more commands after timeout error", %{sandbox: sandbox} do
    {:error, {_, sandbox}} = Sandbox.execute(":timer.sleep(100)", sandbox, timeout: 50)

    assert {:success, {3, _}} = Sandbox.execute("1 + 2", sandbox)
  end
end
