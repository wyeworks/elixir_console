defmodule ElixirConsoleWeb.LiveMonitor do
  @moduledoc """
  This module monitors the created sandbox processes. Gives a way to dispose
  those processes when they are not longer used.

  The code is based on https://github.com/phoenixframework/phoenix_live_view/issues/123
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def monitor(pid, view_module, meta) do
    GenServer.call(__MODULE__, {:monitor, pid, view_module, meta})
  end

  def update_sandbox(pid, view_module, meta) do
    GenServer.call(__MODULE__, {:update_sandbox, pid, view_module, meta})
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def handle_call({:monitor, pid, view_module, meta}, _from, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta})}}
  end

  def handle_call({:update_sandbox, pid, view_module, meta}, _from, %{views: views} = state) do
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {{module, meta}, new_views} = Map.pop(state.views, pid)
    module.unmount(meta)
    {:noreply, %{state | views: new_views}}
  end
end
