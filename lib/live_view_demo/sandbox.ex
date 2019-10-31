defmodule LiveViewDemo.Sandbox do
  require Logger

  # 30 kb
  @max_memory_usage 1024 * 30

  def execute(command, bindings) do
    task = Task.async(fn -> execute_code(command, bindings) end)

    case check_memory_and_result(task) do
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

  defp check_memory_and_result(task, attempts \\ 100)

  defp check_memory_and_result(task, 0) do
    Task.shutdown(task)
    :timeout
  end

  defp check_memory_and_result(task, attempts) do
    case Task.yield(task, 50) do
      {:ok, result} ->
        {:ok, result}

      nil ->
        if allowed_memory_usage?(task) do
          check_memory_and_result(task, attempts - 1)
        else
          Task.shutdown(task)
          :memory_abuse
        end
    end
  end

  defp allowed_memory_usage?(task) do
    {:memory, memory} = Process.info(task.pid, :memory)
    memory <= @max_memory_usage
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
