defmodule ChessTest do
  use ExUnit.Case
  require Logger

  defp pgn_mentor_files(opts \\ []) do
    "https://www.pgnmentor.com/files.html"
    |> HTTPoison.get!()
    |> (fn %HTTPoison.Response{body: body} -> body end).()
    |> Floki.parse_document!()
    |> Floki.find("a.view")
    |> Enum.filter(fn item ->
      [name] = Floki.attribute(item, "href")
      # Path.extname(name) == ".pgn" or Path.extname(name) == ".zip"
      Path.extname(name) == ".pgn"
    end)
    |> Enum.uniq()
    |> Enum.take_random(Keyword.get(opts, :count, 10))
    |> Enum.map(fn item ->
      [name] = Floki.attribute(item, "href")
      # id = :sha |> :crypto.hash(name) |> Base.encode64()

      type =
        case Path.extname(name) do
          ".pgn" -> :pgn
          ".zip" -> :zip
          _other -> :unsupported
        end

      download_path = Path.join(["/tmp/pgnmentor", name])
      downloaded? = File.exists?(download_path)

      unless downloaded? do
        download_path
        |> Path.dirname()
        |> File.mkdir_p!()

        case HTTPoison.request(:get, "https://www.pgnmentor.com/#{name}") do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            File.write!(download_path, body)

          {:ok, %HTTPoison.Response{status_code: 404}} ->
            Logger.warn("File not found: #{name}")

          {:error, reason} ->
            Logger.error("Failed to download file: #{name} - #{inspect(reason)}")
        end
      end

      %{
        name: name,
        type: type,
        download_path: download_path
      }
    end)
  end

  defp parse_pgn(file_content) do
    file_content
    |> String.replace("\r", "")
    |> String.split("\n\n")
    |> Enum.chunk_every(2)
    |> Enum.map(&parse_pgn_game/1)
    |> Enum.map(&IO.inspect/1)
  end

  defp parse_pgn_game([tags, moves]),
    do: {:ok, %{tags: parse_tags(tags), moves: parse_moves(moves)}}

  defp parse_pgn_game([""]), do: {:error, :invalid_game}
  defp parse_pgn_game([_]), do: {:error, :invalid_game}

  defp parse_tags(tags_str) when is_binary(tags_str) do
    tags_str
    |> String.split("\n")
    |> Enum.map(fn m ->
      m
      |> String.replace("[", "")
      |> String.replace("]", "")
      |> String.split(" ", parts: 2)
    end)
    |> Enum.map(&parse_tag_key/1)
    |> Enum.reject(fn(i) -> i == :invalid_tag end)
  end

  defp parse_tag_key([key, value]), do: {key, String.replace(value, "\"", "")}
  defp parse_tag_key([_]), do: :invalid_tag

  defp parse_moves(moves_str) do
    moves_str
    |> String.replace("\r", "")
    |> String.replace("\n", " ")
    |> String.replace(~r/\d+\./, ",")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn move -> String.split(move, " ") end)
    |> List.flatten()
    |> Enum.chunk_every(2)
    |> Enum.with_index(1)
    |> Enum.map(&parse_move/1)
  end

  defp parse_move({[result], number}) do
    %{number: number, result: result}
  end

  defp parse_move({[white, black], number}) do
    %{
       number: number,
       white: white,
       black: black
    }
  end
  
#  defp parse_move_san(san, number, color) do
#    is_chess = String.contains?(san, "+")
#    is_kill = String.contains?(san, "x")
#
#    parts =
#      san
#      |> String.replace("+", "")
#      |> String.codepoints()
#
#    %{
#      is_chess: is_chess,
#      is_kill: is_kill,
#      san: san,
#      codepoints: parts
#    }
#
#    #    case String.codepoints(san) do
#    #      ["0", "-", "0"] ->
#    #        %{type: :castling_kingside}
#    #
#    #      ["0", "-", "0", "-", "0"] ->
#    #        %{type: :castling_queenside}
#    #
#    #      [to_file, to_rank] ->
#    #        %{type: :move, figure: "p", to_file: to_file, to_rank: to_rank}
#    #
#    #      [figure, to_file, to_rank] when figure in ["P", "R", "N", "B", "Q", "K"] ->
#    #        %{type: :move, figure: String.downcase(figure), to_file: to_file, to_rank: to_rank}
#    #
#    #      [figure, from_file, to_file, to_rank] when figure in ["P", "R", "N", "B", "Q", "K"] and from_file in ["a", "b", "c", "d", "e", "f", "g", "h"] ->
#    #        %{type: :move, figure: String.downcase(figure), from_file: from_file, to_file: to_file, to_rank: to_rank}
#    #
#    #      [figure, "x", to_file, to_rank] when figure in ["P", "R", "N", "B", "Q", "K"] ->
#    #        %{type: :kill, figure: String.downcase(figure), to_file: to_file, to_rank: to_rank}
#    #
#    #
#    #      _other ->
#    #        san
#    #    end
#  end

  # defp parse_move("0-0"), do: :castling_kingside
  # defp parse_move("0-0-0"), do: :castling_queenside
  # defp parse_move_san(<<file, rank>>), do: {:move, "p", file, rank}
  # defp parse_move_san(<<figure, file, rank>>), do: {:move, String.downcase(figure), file, rank}
  # defp parse_move_san(i), do: i

  #  defp parse_move_san(<<figure, file, rank>>), do: {figure, file, rank}
  #  defp parse_move_san(<<file, rank>>), do: {"p", file, rank}
  #  defp parse_move_san(<<file, "x", file, rank>>), do: {"p", file, rank}

  test "develop" do
    games =
      pgn_mentor_files()
      |> Enum.map(fn %{download_path: download_path} ->
        download_path
        |> File.read!()
        |> parse_pgn()
      end)
      |> List.flatten()

    IO.puts("Games: #{length(games)}")

    #    game = Chess.new_game()
    #    {:ok, game} = Chess.Game.play(game, "e2-e4")
    #    Chess.Game.to_string(game) |> IO.puts()
    #
    #    {:ok, game} = Chess.Game.play(game, "e7-e5")
    #    Chess.Game.to_string(game) |> IO.puts()
    #
    #    {:ok, game} = Chess.Game.play(game, "d1-h5")
    #    Chess.Game.to_string(game) |> IO.puts()
    #
    #    {:error, "Invalid move format"} = Chess.Game.play(game, "e4")
    #    {:error, "Square does not have figure for move"} = Chess.Game.play(game, "e2-e4")
    #    {:error, "There is barrier at square " <> _square} = Chess.Game.play(game, "0-0")
  end

#  test "play with pgn" do
#    game = Chess.new_game()
#    {:ok, game} = Chess.Game.play(game, "e2-e4")
#
#    Chess.Game.to_string(game) |> IO.puts()
#    IO.inspect(game.history)
#
#  end
#
#  defmodule ChessUtils do
#    defp parse_san_move(move) do
#      {piece, target} =
#        case String.split_at(move, -2) do
#          {_, target} -> {"P", target}  # Assume it's a pawn move if piece is missing
#          {piece, target} -> {String.upcase(piece), target}
#          _ -> {nil, nil}
#        end
#
#      {piece, target}
#    end
#
#    defp get_starting_square("P", target) do
#      String.slice(target, 0..0) <> "2"  # Assuming it's a white pawn
#    end
#    defp get_starting_square(piece, target) do
#      String.upcase(piece) <> target
#    end
#
#    def convert_to_long_algebraic(san_move) do
#      {piece, target} = parse_san_move(san_move)
#      starting_square = get_starting_square(piece, target)
#      if starting_square != nil do
#        starting_square <> "-" <> target
#      else
#        "Invalid SAN move"
#      end
#    end
#  end
#
#
#  test "something" do
#    IO.puts ChessUtils.convert_to_long_algebraic("e4")  # Output: "e2-e4"
#    IO.puts ChessUtils.convert_to_long_algebraic("e3")
#  end


end
