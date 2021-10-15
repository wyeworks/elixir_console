defmodule ElixirConsoleWeb.ConsoleLive.Bindings do
  use Surface.Component

  @doc "Keyword list of bindings"
  prop bindings, :keyword

  def render(assigns) do
    ~F"""
    <div class="bg-teal-700 p-2 overflow-y-scroll max-h-1/3">
      <h2 class="font-medium">Current Bindings</h2>
      <ul>
      {#for {key, value} <- @bindings}
        <li class="truncate">{key}: <code class="text-teal-300">{inspect(value)}</code></li>
      {#else}
        <code class="text-teal-300 text-sm">No bindings yet!</code>
      {/for}
      </ul>
    </div>
    """
  end
end
