defmodule Chess.Figure do
  @moduledoc """
  Defines a struct and functions for working with figures.
  """

  @type t() :: %__MODULE__{color: String.t(), type: String.t()}
  defstruct color: "", type: ""

  alias Chess.Figure

  @doc """
  Creates a figure

  ## Options

      color - w or b
      type - p (Pion), r (Rook), n (Knight), b (Bishop), q (Queen), k (King)

  ## Examples

      iex> Chess.Figure.new("w", "p")
      %Chess.Figure{color: "w", type: "p"}

  """
  def new(color, type)
      when color in ["w", "b"] and type in ["p", "r", "n", "b", "q", "k"],
      do: %Figure{color: color, type: type}

  @doc """
  Returns the figures unicode icon

  ## Examples

      iex> Chess.Figure.icon(%Chess.Figure{type: "p", color: "w"})
      "♙"

  """
  @spec icon(figure :: Figure.t()) :: String.t()
  def icon(%__MODULE__{type: "p", color: "w"}), do: "\u2659"
  def icon(%__MODULE__{type: "p", color: "b"}), do: "\u265F"
  def icon(%__MODULE__{type: "r", color: "w"}), do: "\u2656"
  def icon(%__MODULE__{type: "r", color: "b"}), do: "\u265C"
  def icon(%__MODULE__{type: "k", color: "w"}), do: "\u2654"
  def icon(%__MODULE__{type: "k", color: "b"}), do: "\u265A"
  def icon(%__MODULE__{type: "q", color: "w"}), do: "\u2655"
  def icon(%__MODULE__{type: "q", color: "b"}), do: "\u265B"
  def icon(%__MODULE__{type: "n", color: "w"}), do: "\u2658"
  def icon(%__MODULE__{type: "n", color: "b"}), do: "\u265E"
  def icon(%__MODULE__{type: "b", color: "w"}), do: "\u2657"
  def icon(%__MODULE__{type: "b", color: "b"}), do: "\u265D"
  def icon(:empty), do: " "
end
