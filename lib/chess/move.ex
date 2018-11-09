defmodule Chess.Move do
  @moduledoc """
  Move module
  """

  @x_fields ["a", "b", "c", "d", "e", "f", "g", "h"]
  @y_fields ["1", "2", "3", "4", "5", "6", "7", "8"]

  alias Chess.{Game, Move, Position}

  use Move.Parse
  use Move.FigureRoute
  use Move.Barriers
  use Move.Destination

  @doc """
  Makes new move
  """
  def new(%Game{squares: squares, current_fen: current_fen, history: history}, move) do
    try do
      current_position = Position.from_fen(current_fen)

      [move_from, move_to] = parse_move(move)

      figure = find_figure(squares[:"#{move_from}"])

      check_active_player(figure, current_position.active)

      [route, distance] = check_route_for_figure(figure, move_from, move_to)

      if figure.type != "n" do
        check_barriers_on_route(squares, move_from, route, distance)
      end

      {is_attack, squares} = check_destination(squares, move_from, move_to, squares[:"#{move_to}"], figure, current_position.en_passant)

      {:ok,
        %Game{
          squares: squares,
          current_fen: Position.new(squares, current_position, figure, distance, move_to, is_attack) |> Position.to_fen,
          history: Enum.concat(history, %{fen: current_fen, move: move})
        }
      }
    rescue
      error -> {:error, error.message}
    end
  end

  defp parse_move(move) do
    move
    |> check_move_format()
    |> String.split("-")
  end

  defp find_figure(figure) when figure == nil do
    raise "Square does not have figure for move"
  end

  defp find_figure(figure) do
    figure
  end

  defp check_active_player(%Figure{color: color}, active) do
    if String.first(color) != active  do
      raise "This is not move of #{color} player"
    end
  end

  defp check_route_for_figure(figure, move_from, move_to) do
    route = calc_route(String.split(move_from, "", trim: true), String.split(move_to, "", trim: true))
    distance = calc_distance(route)

    if distance == 0 do
      raise "You need to move figure somewhere"
    end

    check_figure_route(figure, route, String.split(move_from, "", trim: true))
    [route, distance]
  end

  defp calc_route([move_from_x, move_from_y], [move_to_x, move_to_y]) do
    [
      Enum.find_index(@x_fields, fn x -> x == move_to_x end) - Enum.find_index(@x_fields, fn x -> x == move_from_x end),
      Enum.find_index(@y_fields, fn y -> y == move_to_y end) - Enum.find_index(@y_fields, fn y -> y == move_from_y end)
    ]
  end

  defp calc_distance(route) do
    route
    |> Enum.map(fn x -> abs(x) end)
    |> Enum.max
  end
end
