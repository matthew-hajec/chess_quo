defmodule EasyChess.Lobby do
  require Logger

  alias EasyChess.Chess.Game

  @lobby_charset "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lobby_code_length 8
  # Lobby expires after 1 hour
  @lobby_expire_seconds 3600

  defp generate_code do
    @lobby_charset
    |> String.graphemes()
    |> Enum.take_random(@lobby_code_length)
    |> Enum.join()
  end

  defp generate_secret do
    :crypto.strong_rand_bytes(24)
    |> Base.encode64()
  end

  def create_lobby(password, host_color) do
    code = generate_code()
    host_secret = generate_secret()
    guest_secret = generate_secret()
    game = Game.new()

    # Perform a MULTI/EXEC transaction to ensure that all keys are set atomically
    case Redix.transaction_pipeline(:redix, [
           ["SETNX", "lobby:#{code}:password", password],
           ["SETNX", "lobby:#{code}:host_secret", host_secret],
           ["SETNX", "lobby:#{code}:guest_secret", guest_secret],
           ["SETNX", "lobby:#{code}:host_color", host_color],
           ["SETNX", "game:#{code}", Poison.encode!(game)],

           # Expire all keys after 1 hour
           ["EXPIRE", "lobby:#{code}:password", @lobby_expire_seconds],
           ["EXPIRE", "lobby:#{code}:host_secret", @lobby_expire_seconds],
           ["EXPIRE", "lobby:#{code}:guest_secret", @lobby_expire_seconds],
           ["EXPIRE", "lobby:#{code}:host_color", @lobby_expire_seconds],
           ["EXPIRE", "game:#{code}", @lobby_expire_seconds]
         ]) do
      {:ok, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]} ->
        {:ok, code, host_secret, guest_secret}

      {:ok, [0, _, _, _, _, _, _, _, _, _]} ->
        # If the code already exists, try a new code.
        create_lobby(password, host_color)


      {:error, reason} ->
        Logger.error("Failed to create lobby: #{inspect reason}")
        {:error, reason}
    end
  end

  def is_valid_secret?(code, :host, secret) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:host_secret"]) do
      {:ok, value} ->
        {:ok, secret == value}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def is_valid_secret?(code, :guest, secret) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:guest_secret"]) do
      {:ok, value} ->
        {:ok, secret == value}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def correct_password?(code, password) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:password"]) do
      {:ok, value} ->
        {:ok, password == value}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def lobby_exists?(code) do
    case Redix.command(:redix, ["EXISTS", "lobby:#{code}:password"]) do
      {:ok, 1} ->
        {:ok, true}

      {:ok, 0} ->
        {:ok, false}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_color(code, :host) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:host_color"]) do
      {:ok, color} ->
        {:ok, color}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_color(code, :guest) do
    # Opposite of the host color
    case get_color(code, :host) do
      {:ok, "white"} ->
        {:ok, "black"}

      {:ok, "black"} ->
        {:ok, "white"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_secret(code, :host) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:host_secret"]) do
      {:ok, secret} ->
        {:ok, secret}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_secret(code, :guest) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:guest_secret"]) do
      {:ok, secret} ->
        {:ok, secret}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_game(code) do
    case Redix.command(:redix, ["GET", "game:#{code}"]) do
      {:ok, encoded_game} ->
        {:ok, Poison.decode!(encoded_game, as: %Game{})}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def save_game(code, game) do
    case Poison.encode(game) do
      {:ok, encoded_game} ->
        case Redix.command(:redix, ["SET", "game:#{code}", encoded_game]) do
          {:ok, _} ->
            {:ok, game}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
