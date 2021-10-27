defmodule ElixirConsoleWeb.ConsoleLive.Suggestions do
  use Surface.Component

  @doc "List of suggestions"
  prop suggestions, :list

  def render(assigns) do
    ~F"""
    <h2 class="font-medium">Suggestions:</h2>
    <ul id="suggestions-list">
      {#for suggestion <- @suggestions}
        <li>{suggestion}</li>
      {/for}
    </ul>
    """
  end
end
