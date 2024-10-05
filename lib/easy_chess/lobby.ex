defmodule EasyChess.Lobby do
  @lobby_charset "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lobby_code_length 8
  @lobby_expire_seconds 3600 # Lobby expires after 1 hour

  defp generate_lobby_code(password) do
    code =
      @lobby_charset
      |> String.graphemes()
      |> Enum.take_random(@lobby_code_length)
      |> Enum.join()

    # Check REDIS for the code
    case Redix.command(:redix, ["SETNX", "lobby:#{code}:password", password]) do
      {:ok, 1} ->
        {:ok, code}

      {:ok, 0} ->
        # If the code already exists, try a new code.
        generate_lobby_code(password)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate_session_secrets(code) do
    host_secret =
      :crypto.strong_rand_bytes(24)
      |> Base.encode64()

    guest_secret =
      :crypto.strong_rand_bytes(24)
      |> Base.encode64()

    with {:ok, "OK"} <- Redix.command(:redix, ["SET", "lobby:#{code}:host_secret", host_secret, "EX", @lobby_expire_seconds]),
         {:ok, "OK"} <- Redix.command(:redix, ["SET", "lobby:#{code}:guest_secret", guest_secret, "EX", @lobby_expire_seconds]) do
      {:ok, host_secret, guest_secret}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def is_valid_secret?(code, :host, secret) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:host_secret"]) do
      {:ok, value} ->
        secret == value

      {:error, reason} ->
        {:error, reason}
    end
  end

  def is_valid_secret?(code, :guest, secret) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:guest_secret"]) do
      {:ok, value} ->
        secret == value

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_lobby_secrets(code) do
    with {:ok, host_secret} <- Redix.command(:redix, ["GET", "lobby:#{code}:host_secret"]),
         {:ok, guest_secret} <- Redix.command(:redix, ["GET", "lobby:#{code}:guest_secret"]) do
      {:ok, host_secret, guest_secret}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def compare_password(code, password) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:password"]) do
      {:ok, value} ->
        password == value

      {:error, reason} ->
        {:error, reason}
    end
  end

  def lobby_exists?(code) do
    case Redix.command(:redix, ["EXISTS", "lobby:#{code}:password"]) do
      {:ok, 1} ->
        true

      {:ok, 0} ->
        false

      {:error, reason} ->
        {:error, reason}
    end
  end

  def set_host_color(code, color) do
    case Redix.command(:redix, ["SET", "lobby:#{code}:host_color", color, "EX", @lobby_expire_seconds]) do
      {:ok, "OK"} ->
        {:ok, "OK"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_host_color(code) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:host_color"]) do
      {:ok, color} ->
        {:ok, color}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_lobby(password, host_color) do
    with {:ok, code} <- generate_lobby_code(password),
         {:ok, host_secret, guest_secret} <- generate_session_secrets(code),
         {:ok, _} <- set_host_color(code, host_color),
         {:ok, _game} <- EasyChess.Chess.GamesManager.create_game(code) do
      {:ok, code, host_secret, guest_secret}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
