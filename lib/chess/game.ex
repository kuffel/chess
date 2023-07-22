defmodule Chess.Game do
  @moduledoc """
  Game module
  """

  alias Chess.{Game, Square, Move, Position, Utils}
  use Game.CheckStatus
  use Utils

  defstruct squares: nil,
            current_fen: Position.new() |> Position.to_fen(),
            history: [],
            status: :playing,
            check: nil

  @doc """
  Creates a game

  ## Examples

      iex> Chess.Game.new()
      %Chess.Game{squares: [...]}

  """
  def new do
    squares = Square.prepare_for_new_game()

    %Game{squares: squares}
  end

  @doc """
  Creates a game from FEN-notation

  ## Examples

      iex> Chess.Game.new("FEN")
      %Chess.Game{squares: [...]}

  """
  def new(current_fen) when is_binary(current_fen) do
    position = Position.new(current_fen)
    squares = Square.prepare_from_position(position)
    [status, check] = check_avoiding(squares, position.active)

    %Game{squares: squares, current_fen: current_fen, status: status, check: check}
  end

  @doc """
  Makes a play

  ## Parameters

    - game: game object
    - value: move is represented like e2-e4
    - promotion: if pion achives last line then it will promote to this figure

  ## Examples

      iex> Chess.Game.play(%Game{}, "e2-e4")
      {:ok, %Game{}}

      iex> Chess.Game.play(%Game{}, "e2-e5")
      {:error, ""}

      iex> Chess.Game.play(%Game{}, "e7-e8", "q")
      {:ok, %Game{}}

  """
  def play(%Game{} = game, value, promotion \\ "q")
      when is_binary(value) and promotion in ["r", "n", "b", "q"],
      do: Move.new(game, value, promotion)
end
