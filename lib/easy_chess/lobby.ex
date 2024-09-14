defmodule EasyChess.Lobby do
  @lobby_charset "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lobby_code_length 8

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

    with {:ok, "OK"} <- Redix.command(:redix, ["SET", "lobby:#{code}:host_secret", host_secret]),
         {:ok, "OK"} <- Redix.command(:redix, ["SET", "lobby:#{code}:guest_secret", guest_secret]) do
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
    IO.inspect("Comparing password #{password} for lobby #{code}")

    case Redix.command(:redix, ["GET", "lobby:#{code}:password"]) do
      {:ok, value} ->
        IO.inspect("Password for lobby #{code} is #{value}")
        password == value

      {:error, reason} ->
        IO.inspect("Error getting password for lobby #{code}: #{reason}")
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

  def create_lobby(password) do
    with {:ok, code} <- generate_lobby_code(password),
         {:ok, host_secret, guest_secret} <- generate_session_secrets(code),
         {:ok, _game} <- EasyChess.Chess.GamesManager.create_game(code) do
      {:ok, code, host_secret, guest_secret}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
