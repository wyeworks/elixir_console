defmodule LiveViewDemo.Sandbox do
  require Logger

  @max_memory_kb_default 30

  def execute(command, bindings, opts \\ []) do
    task = Task.async(fn -> execute_code(command, bindings) end)

    timeout = Keyword.get(opts, :timeout, 5000)
    check_every = Keyword.get(opts, :check_every, 20)
    ticks = floor(timeout / check_every)

    # Convert from kb to bytes (* 1024)
    max_memory_kb = Keyword.get(opts, :max_memory_kb, @max_memory_kb_default) * 1024

    case check_task_status(task,
           ticks: ticks,
           check_every: check_every,
           max_memory_kb: max_memory_kb
         ) do
      {:ok, {:success, result}} ->
        {:success, result}

      {:ok, {:error, result}} ->
        {:error, result}

      :timeout ->
        {:error, "The command was cancelled due to timeout"}

      :memory_abuse ->
        {:error, "The command used more memory than allowed"}
    end
  end

  defp check_task_status(task, [{:ticks, 0} | _]) do
    Task.shutdown(task)
    :timeout
  end

  defp check_task_status(
         task,
         [ticks: ticks, check_every: check_every, max_memory_kb: max_memory_kb] = opts
       ) do
    case Task.yield(task, check_every) do
      {:ok, result} ->
        {:ok, result}

      nil ->
        if allowed_memory_usage?(task, max_memory_kb) do
          check_task_status(task, Keyword.put(opts, :ticks, ticks - 1))
        else
          Task.shutdown(task)
          :memory_abuse
        end
    end
  end

  defp allowed_memory_usage?(task, memory_limit) do
    {:memory, memory} = Process.info(task.pid, :memory)
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
