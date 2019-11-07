defmodule LiveViewDemo.SandboxTest do
  use ExUnit.Case
  alias LiveViewDemo.Sandbox

  test "runs a basic command" do
    assert Sandbox.execute("1 + 2", Sandbox.init()) == {:success, {3, []}}
  end

  test "adds a new binding" do
    assert Sandbox.execute("a = 1 + 2", Sandbox.init()) == {:success, {3, [a: 3]}}
  end

  test "updates an existing binding" do
    sandbox = %{ Sandbox.init() | bindings: [a: "foo"] }
    assert Sandbox.execute("a = 1 + 2", sandbox) == {:success, {3, [a: 3]}}
  end

  test "keeps existing bindings" do
    sandbox = %{ Sandbox.init() | bindings: [a: "foo"] }
    assert Sandbox.execute("1 + 2", sandbox) == {:success, {3, [a: "foo"]}}
  end

  test "reports excesive memory usage" do
    assert Sandbox.execute("for i <- 1..70_000, do: i", Sandbox.init()) ==
             {:error, "The command used more memory than allowed"}
  end

  test "reports excesive memory usage with custom memory limit" do
    assert Sandbox.execute("for i <- 1..30_000, do: i", Sandbox.init(), max_memory_kb: 10) ==
             {:error, "The command used more memory than allowed"}
  end

  test "reports excesive time spent on the execution" do
    assert Sandbox.execute(":timer.sleep(100)", Sandbox.init(), timeout: 50) ==
             {:error, "The command was cancelled due to timeout"}
  end
end
