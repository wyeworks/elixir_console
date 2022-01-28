defmodule ElixirConsoleWeb.ConsoleLive.Helpers do
  @moduledoc """
  This module provides very simple helpers to use in templates and avoid repetition
  """

  import Phoenix.LiveView.Helpers, only: [sigil_H: 2]

  def prompt(assigns) do
    ~H(> )
  end
end
