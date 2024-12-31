defmodule ChessQuo.Lobby do
  require Logger

  alias ChessQuo.Lobby, as: Lobby
  alias ChessQuo.Chess.Game, as: Game
  alias ChessQuo.GameTypes, as: Types

  @lobby_charset "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @lobby_code_length 8
  # Lobby expires after 4 hours
  @lobby_expire_seconds 3600 * 4

  @type t :: %Lobby{
          code: String.t(),
          password: String.t(),
          host_secret: String.t(),
          guest_secret: String.t(),
          host_color: Types.color(),
          game: Game.t(),
          draw_request_by: Types.player_type() | nil,
          guest_joined: boolean()
        }

  defstruct [
    :code,
    :password,
    :host_secret,
    :guest_secret,
    :host_color,
    :game,
    :draw_request_by,
    :guest_joined
  ]

  @spec new(String.t(), Types.color()) :: Lobby.t()
  def new(password, host_color) do
    %Lobby{
      code: generate_code(),
      password: password,
      host_secret: generate_secret(),
      guest_secret: generate_secret(),
      host_color: host_color,
      game: Game.new(),
      draw_request_by: nil,
      guest_joined: false
    }
  end

  @spec save(Lobby.t()) ::
          :ok | {:error, atom()}
  def save(lobby) do
    # Build the list of commands to send to Redis in a transaction pipeline
    commands = [
      ["SET", "lobby:#{lobby.code}:password", lobby.password, "EX", @lobby_expire_seconds],
      ["SET", "lobby:#{lobby.code}:host_secret", lobby.host_secret, "EX", @lobby_expire_seconds],
      [
        "SET",
        "lobby:#{lobby.code}:guest_secret",
        lobby.guest_secret,
        "EX",
        @lobby_expire_seconds
      ],
      [
        "SET",
        "lobby:#{lobby.code}:host_color",
        to_string(lobby.host_color),
        "EX",
        @lobby_expire_seconds
      ],
      [
        "SET",
        "lobby:#{lobby.code}:game",
        Poison.encode!(lobby.game),
        "EX",
        @lobby_expire_seconds
      ],
      [
        "SET",
        "lobby:#{lobby.code}:draw_request_by",
        to_string(lobby.draw_request_by),
        "EX",
        @lobby_expire_seconds
      ],
      ["SET", "lobby:#{lobby.code}:guest_joined", to_string(lobby.guest_joined)]
    ]

    # Redis returns "OK for successful SET commands
    success_value = List.duplicate("OK", length(commands))

    case Redix.transaction_pipeline(:redix, commands) do
      {:ok, ^success_value} ->
        :ok

      # If we get an :ok tuple but not all "OK" replies, something failed.
      {:ok, _} ->
        {:error, :transaction_failed}

      # Any Redis error or connection error is returned here.
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec load(String.t()) :: {:ok, Lobby.t()} | {:error, atom()}
  def load(code) do
    keys = [
      "lobby:#{code}:password",
      "lobby:#{code}:host_secret",
      "lobby:#{code}:guest_secret",
      "lobby:#{code}:host_color",
      "lobby:#{code}:game",
      "lobby:#{code}:draw_request_by",
      "lobby:#{code}:guest_joined"
    ]

    # Retrieve all fields in one MGET command
    case Redix.command(:redix, ["MGET" | keys]) do
      {:ok,
       [
         password,
         host_secret,
         guest_secret,
         host_color_str,
         game_json,
         draw_request_by_str,
         guest_joined_str
       ]} ->
        # If any key is nil, this lobby code does not exist or is incomplete.
        if Enum.any?(
             [
               password,
               host_secret,
               guest_secret,
               host_color_str,
               game_json,
               draw_request_by_str,
               guest_joined_str
             ],
             &is_nil/1
           ) do
          {:error, :not_found}
        else
          # Convert host_color back to an atom.
          host_color = String.to_existing_atom(host_color_str)

          # Decode the game JSON string back to the Game struct/map.
          # Adjust if your Poison-encoded data needs special handling.
          game = Poison.decode!(game_json, as: %Game{})

          IO.puts(draw_request_by_str)

          # Convert draw_request_by back to an atom or nil.
          draw_request_by =
            case draw_request_by_str do
              "" -> nil
              other -> String.to_existing_atom(other)
            end

          # Convert guest_joined back to a boolean.
          guest_joined = guest_joined_str == "true"

          # Build the Lobby struct.
          lobby = %Lobby{
            code: code,
            password: password,
            host_secret: host_secret,
            guest_secret: guest_secret,
            host_color: host_color,
            game: game,
            draw_request_by: draw_request_by,
            guest_joined: guest_joined
          }

          {:ok, lobby}
        end

      {:ok, _unexpected} ->
        # If the shape of the result is not what's expected, consider it missing.
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

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
end
