defmodule Chess.FigureTest do
  use ExUnit.Case
  doctest Chess.Figure
  alias Chess.Figure

  figures = [
    {"white pawn", "w", "p", "♙"},
    {"black pawn", "b", "p", "♟"},
    {"white rook", "w", "r", "♖"},
    {"black rook", "b", "r", "♜"},
    {"white knight", "w", "n", "♘"},
    {"black knight", "b", "n", "♞"},
    {"white bishop", "w", "b", "♗"},
    {"black bishop", "b", "b", "♝"},
    {"white queen", "w", "q", "♕"},
    {"black queen", "b", "q", "♛"},
    {"white king", "w", "k", "♔"},
    {"black king", "b", "k", "♚"}
  ]

  test "new/2 should raise an error when color and type are not supported" do
    assert_raise FunctionClauseError, ~r/^no function clause matching/, fn ->
      Figure.new("x", "y")
    end
  end

  for {name, color, type, _} <- figures do
    test "new/2 should support #{name}" do
      assert Figure.new(unquote(color), unquote(type)) == %Figure{
               color: unquote(color),
               type: unquote(type)
             }
    end
  end

  test "icon/1 should return an empty string when figure is :empty" do
    assert Figure.icon(:empty) == " "
  end

  for {name, color, type, icon} <- figures do
    test "icon/1 should support #{name}" do
      assert Figure.icon(%Figure{color: unquote(color), type: unquote(type)}) == unquote(icon)
    end
  end
end
