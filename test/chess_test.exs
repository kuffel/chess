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
  end

  defp parse_tag_key([key, value]), do: {:ok, {key, String.replace(value, "\"", "")}}
  defp parse_tag_key([_]), do: {:error, :invalid_tag}

  defp parse_moves(moves_str) do
    moves_str
    |> String.replace("\r", "")
    |> String.replace("\n", "")
    |> String.replace(~r/(\d)\./, "")
    |> String.split(" ")
    |> Enum.map(&parse_move_san/1)

    # |> Enum.chunk_every(2)
  end

  # defp parse_move_san(<<figure, "x", file, rank>>), do: {figure, file, rank}
  # defp parse_move_san(<<figure, file, rank>>), do: {figure, file, rank}
  # defp parse_move_san(<<file, rank>>), do: {"p", file, rank}
  # defp parse_move_san(<<figure_from, file_from, file_from, figure_to, file_to, file_to>>), do: {figure_from, file_from, file_from, figure_to, file_to, file_to}

  defp parse_move_san(i), do: i

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
end
