defmodule LiveViewDemo.SandboxTest do
  use ExUnit.Case
  alias LiveViewDemo.Sandbox

  test "runs a basic command" do
    assert Sandbox.execute("1 + 2", []) == {:success, {3, []}}
  end

  test "adds a new binding" do
    assert Sandbox.execute("a = 1 + 2", []) == {:success, {3, [a: 3]}}
  end

  test "updates an existing binding" do
    assert Sandbox.execute("a = 1 + 2", a: "foo") == {:success, {3, [a: 3]}}
  end

  test "keeps existing bindings" do
    assert Sandbox.execute("1 + 2", a: "foo") == {:success, {3, [a: "foo"]}}
  end

  test "reports excesive memory usage" do
    assert Sandbox.execute("for i <- 1..70_000, do: i", a: "foo") ==
             {:error, "The command used more memory than allowed"}
  end

  test "reports excesive time spent on the execution" do
    assert Sandbox.execute(":timer.sleep(6000)", a: "foo") ==
             {:error, "The command was cancelled due to timeout"}
  end
end
