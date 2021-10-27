defmodule ElixirConsoleWeb.ConsoleLive.SidebarComponent do
  @moduledoc """
  Live component module that implements the portion of the UI corresponding to
  the sidebar. It displays the bindings, Elixir functions help and some static
  information.
  """

  use Surface.Component

  alias ElixirConsoleWeb.ConsoleLive.{Bindings, Suggestions, ContextualHelp, Instructions}

  prop sandbox, :map

  prop suggestions, :list

  prop contextual_help, :map

  def render(assigns) do
    ~F"""
    <div class="w-full sm:w-32 md:w-1/3 h-32 sm:h-full bg-teal-800 text-gray-200 overflow-scroll flex flex-col">
      <Bindings bindings={@sandbox.bindings} />
      <div class="flex-1 flex flex-col justify-end p-2">
        {#if @suggestions != []}
          <Suggestions suggestions={@suggestions}/>
        {#elseif @contextual_help}
          <ContextualHelp {...@contextual_help} />
        {#else}
          <Instructions />
        {/if}
      </div>
    </div>
    """
  end
end
