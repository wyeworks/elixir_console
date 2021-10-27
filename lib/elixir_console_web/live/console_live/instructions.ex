defmodule ElixirConsoleWeb.ConsoleLive.Instructions do
  use Surface.Component

  def render(assigns) do
    ~F"""
    <h2 class="underline mb-3">INSTRUCTIONS</h2>
    <p>[UP] [DOWN]: Navigate through commands history</p>
    <p>[TAB]: Get suggestions or autocomplete while typing</p>
    <p class="text-sm mt-3"> You can see the history panel that includes all your commands and their output.
    Click on any Elixir function to see here the corresponding documentation.</p>
    <h2 class="underline mt-5 mb-3">ABOUT SECURITY</h2>
    <p class="text-sm">Please note some features of the language are not safe to run in a shared environment like this console.
    If you are interested in knowing more about the limitations, you must <a class="underline" href="https://github.com/wyeworks/elixir_console#how-much-elixir-can-i-run-in-the-web-console">read here</a>.</p>
    <p class="text-sm">Please report any security vulnerabilities to
      <a class="underline" href="mailto:elixir-console-security@wyeworks.com">elixir-console-security@wyeworks.com</a>.
    </p>
    """
  end
end
