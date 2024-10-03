defmodule EasyChess.Chess.GamesManager do
  @moduledoc """
  Manages creating, updating, and deleting chess games from a shared database.

  Uses the Redix library to interact with Redis
  """
  alias EasyChess.Chess.Game

  @redix_pool :redix

  @doc """
  Creates a new game with the given code.
  """
  def create_game(code) do
    # Create a new game and save it to the database
    game = Game.new()
    save_game(code, game)
  end

  @doc """
  Saves the state of a given game to the database.
  """
  def save_game(code, game) do
    # Encode the game state and then save to the database
    with {:ok, encoded_game} <- Poison.encode(game),
         IO.inspect("Saving game: #{inspect(encoded_game)}"),
         {:ok, _} <- Redix.command(@redix_pool, ["SET", "game:#{code}", encoded_game]) do
      {:ok, game}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieves the state of a game from the database.
  """
  def get_game(code) do
    # Get the game state from the database and then decode it
    case Redix.command(@redix_pool, ["GET", "game:#{code}"]) do
      {:ok, encoded_game} ->
        {:ok, Poison.decode!(encoded_game, as: %Game{})}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
