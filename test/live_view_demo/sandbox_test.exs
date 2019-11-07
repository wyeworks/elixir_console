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

  test "reports excesive memory usage", %{sandbox: sandbox} do
    assert Sandbox.execute("for i <- 1..70_000, do: i", sandbox) ==
             {:error, "The command used more memory than allowed"}
  end

  test "reports excesive memory usage with custom memory limit", %{sandbox: sandbox} do
    assert Sandbox.execute("for i <- 1..30_000, do: i", sandbox, max_memory_kb: 10) ==
             {:error, "The command used more memory than allowed"}
  end

  test "reports excesive time spent on the execution", %{sandbox: sandbox} do
    assert Sandbox.execute(":timer.sleep(100)", sandbox, timeout: 50) ==
             {:error, "The command was cancelled due to timeout"}
  end
end
