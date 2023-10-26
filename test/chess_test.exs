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


#  test "develop" do
#    games =
#      pgn_mentor_files()
#      |> Enum.map(fn %{download_path: download_path} ->
#        download_path
#        |> File.read!()
#        |> parse_pgn()
#      end)
#      |> List.flatten()
#
#    IO.puts("Games: #{length(games)}")
#  end

  test "develop - PGN SAN" do
  end

  def parse_fen(fen) when is_binary(fen) do
    with groups <- String.split(fen),
         6 <- length(groups) do

#      %{
#        pieces: pieces,
#        active_color: active_color,
#        castling: castling,
#        en_passant_target_square: en_passant_target_square,
#        halfmoves: halfmoves,
#        moves: moves
#      }
      {:ok, groups}
    else
      p when is_number(p) ->
        {:error, :fen_groups_length}
    end
  end



  test "develop - FEN" do


    assert parse_fen("SOMETHING") == {:error, :fen_groups_length}
    assert parse_fen("SOM ET HING") == {:error, :fen_groups_length}

    assert {:ok, %{
            pieces: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR",
            active_color: "w",
            castling: "KQkq",
            en_passant_target_square: "-",
            halfmoves: "0",
            fullmoves: "1"
           }} = parse_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")






    # FEN defines a game position in one line of text

    # 1. Piece placement data
    # 2. Active color
    # 3. Castling availability
    # 4. En passant target square

#    Chess.Game.new("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
#    |> Chess.Game.to_string()
#    |> IO.puts()
  end






end
