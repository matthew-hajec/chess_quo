defmodule EasyChess.Lobby do
  @lobby_charset "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lobby_code_length 8


  defp generate_lobby_code do
    code = @lobby_charset
    |> String.graphemes()
    |> Enum.take_random(@lobby_code_length)
    |> Enum.join()

    # Check REDIS for the code
    case Redix.command(:redix, ["SETNX", "lobby:#{code}", "created"]) do
      {:ok, 1} ->
        {:ok, code}
      {:ok, 0} ->
        # If the code already exists, try a new code.
        generate_lobby_code()
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

  def compare_secret(code, :host, secret) do
    case Redix.command(:redix, ["GET", "lobby:#{code}:host_secret"]) do
      {:ok, value} ->
        secret == value
      {:error, reason} ->
        {:error, reason}
    end
  end


  def create_lobby do
    with {:ok, code} <- generate_lobby_code(),
         {:ok, host_secret, guest_secret} <- generate_session_secrets(code) do
      {:ok, code, host_secret, guest_secret}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

end
