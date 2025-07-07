defmodule ChessQuoWeb.NewRoomChannel do
  @moduledoc """
  Handles real-time communication for chess game rooms.

  ## Special Channel Events

  - `join`: Allows users to join a room with a specific code and role.
    - Topic format: `"room:<code>"` where `<code>` is the unique identifier for the room.
    - Parameters:
      - `current_game_role`: The role of the user in the game, either "host" or "guest".
      - `current_game_secret`: The secret associated with the user's role for authentication.
    - Error Reasons:
      - `not_authorized`: The user is not authorized to join the room, possibly due to an incorrect secret or role mismatch.
      - `lobby_not_found`: The specified lobby code does not exist or has expired.
      - `unexpected_error`: An unexpected error occurred while processing the join request.


  ## Outgoing Messages
  - `lobby_updated`: Broadcasts the updated lobby state to all subscribers.

  ## Incoming Messages
  - `get_valid_moves`: Requests the valid moves for a specific piece in the game.
    - Parameters:
      - `board_index`: The index of the piece on the board for which valid moves are requested.
    - Error Reasons:
      - `invalid_board_index`: The provided board index is invalid.

  - `make_move`: Requests to make a move in the game and broadcasts the updated game state.
    - Parameters:
      - `from`: The index of the piece being moved.
      - `to`: The index where the piece is being moved to.
      - `promote_to`: Optional parameter to promote a pawn to a different piece type (e.g., "queen", "rook", "bishop", "knight").
    - Error Reasons:
      - `draw_requested`: A draw has been requested by one of the players. No further moves can be made until the draw is resolved.
      - `game_not_ongoing`: The game is not currently ongoing, so no moves
      - `invalid_board_index`: The provided board index is invalid.
      - `not_your_turn`: The player is trying to make a move when it is.
      - `unexpected_error`: An unexpected error occurred while processing the move.

  - `request_draw`: Requests a draw in the game and broadcasts the updated game state.
    - No parameters required.
    - Error Reasons:
      - `draw_already_requested`: A draw has already been requested by one of the players.
      - `game_not_ongoing`: The game is not currently ongoing, so a draw cannot be requested.
      - `unexpected_error`: An unexpected error occurred while processing the draw request.

  - `accept_draw`: Accepts a draw request from the opponent and broadcasts the updated game state.
    - No parameters required.
    - Error Reasons:
      - `no_draw_request`: There is no draw request to accept from the other player.
      - `unexpected_error`: An unexpected error occurred while processing the draw acceptance.

  - `reject_draw`: Rejects a draw request from the opponent and broadcasts the updated game state.
    - No parameters required.
    - Error Reasons:
      - `no_draw_request`: There is no draw request to reject from the other player.
      - `unexpected_error`: An unexpected error occurred while processing the draw rejection.

  - `resign`: Resigns from the game and broadcasts the updated game state.
    - No parameters required.
    - Error Reasons:
      - `game_not_ongoing`: The game is not currently ongoing, so a resignation cannot be made.
      - `unexpected_error`: An unexpected error occurred while processing the resignation.
  """

  use Phoenix.Channel

  alias ChessQuo.Lobby, as: Lobby
  alias ChessQuo.Chess.MoveFinder, as: MoveFinder
  alias ChessQuo.GameTypes, as: Types
  alias ChessQuo.Chess.Piece, as: Piece
  alias ChessQuo.Chess.Game, as: Game

  @doc "Handles user joining a room channel."
  def join(
        "room:" <> code,
        %{"params" => %{"current_game_role" => role, "current_game_secret" => secret}},
        socket
      ) do
    role = role_from_string(role)

    case authorize_lobby(code, role, secret) do
      {:ok, lobby} ->
        socket =
          socket
          |> assign(:current_game_role, role)
          |> assign(:current_game_secret, secret)

        {:ok, %{lobby: lobby}, socket}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  # Checks if the user has provided the correct secret for the specified role and lobby code
  # Returns {:ok, lobby} if authorized, or {:error, reason} if not
  # The error reasons can be:
  # - :not_authorized: The user is not authorized to join the lobby.
  # - :lobby_not_found: The lobby with the specified code was not found.
  # - :unexpected_error: An unexpected error occurred while loading the lobby.
  defp authorize_lobby(code, role, secret) do
    case Lobby.load(code) do
      {:ok, lobby} ->
        if role_secret(lobby, role) == secret do
          {:ok, lobby}
        else
          {:error, :not_authorized}
        end

      {:error, :lobby_not_found} ->
        {:error, :lobby_not_found}

      {:error, _} ->
        {:error, :unexpected_error}
    end
  end

  # Extracts the secret for the specified role
  # If the role is :host, it returns the host secret, for any other role it returns the guest secret
  defp role_secret(%Lobby{host_secret: host_secret}, :host), do: host_secret
  defp role_secret(%Lobby{guest_secret: guest_secret}, _role), do: guest_secret

  # Convert the role string to an atom
  # If the role is "host", we return :host, for any other string we return :guest
  defp role_from_string("host"), do: :host
  defp role_from_string(_), do: :guest
end
