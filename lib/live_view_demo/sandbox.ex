defmodule LiveViewDemo.Sandbox do
  require Logger

  @max_memory_kb_default 30
  @timeout_ms_default 5000
  @check_every_ms_default 20

  @enforce_keys [:pid, :bindings]
  defstruct [:pid, :bindings]

  def init() do
    loop = fn loop_func, parent_pid ->
      receive do
        {:command, command, bindings} ->
          result = execute_code(command, bindings)
          send(parent_pid, {:result, result})

          loop_func.(loop_func, parent_pid)
      end
    end

    parent_pid = self()
    pid = spawn_link(fn -> loop.(loop, parent_pid) end)
    %__MODULE__{pid: pid, bindings: []}
  end

  def execute(command, sandbox, opts \\ []) do
    send(sandbox.pid, {:command, command, sandbox.bindings})

    timeout = Keyword.get(opts, :timeout, @timeout_ms_default)
    check_every = Keyword.get(opts, :check_every, @check_every_ms_default)
    ticks = floor(timeout / check_every)

    # Convert from kb to bytes (* 1024)
    max_memory_kb = Keyword.get(opts, :max_memory_kb, @max_memory_kb_default) * 1024

    case check_execution_status(sandbox.pid,
           ticks: ticks,
           check_every: check_every,
           max_memory_kb: max_memory_kb
         ) do
      {:ok, {:success, {result, bindings}}} ->
        {:success, {result, %{sandbox | bindings: bindings}}}

      {:ok, {:error, result}} ->
        {:error, result}

      :timeout ->
        {:error, "The command was cancelled due to timeout"}

      :memory_abuse ->
        {:error, "The command used more memory than allowed"}
    end
  end

  defp check_execution_status(pid, [{:ticks, 0} | _]) do
    Process.exit(pid, :normal)
    :timeout
  end

  defp check_execution_status(
         pid,
         [ticks: ticks, check_every: check_every, max_memory_kb: max_memory_kb] = opts
       ) do
    receive do
      {:result, result} ->
        {:ok, result}
    after
      check_every ->
        if allowed_memory_usage?(pid, max_memory_kb) do
          check_execution_status(pid, Keyword.put(opts, :ticks, ticks - 1))
        else
          Process.exit(pid, :normal)
          :memory_abuse
        end
    end
  end

  defp allowed_memory_usage?(pid, memory_limit) do
    {:memory, memory} = Process.info(pid, :memory)
    memory <= memory_limit
  end

  defp execute_code(command, bindings) do
    {result, bindings} = Code.eval_string(command, bindings)
    {:success, {result, bindings}}
  catch
    kind, error ->
      error = Exception.normalize(kind, error)
      {:error, inspect(error)}
  end
end
