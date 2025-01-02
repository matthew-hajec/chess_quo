defmodule ChessQuoWeb.RoomChannel do
  use Phoenix.Channel

  alias ChessQuo.Lobby, as: Lobby
  alias ChessQuo.Chess.MoveFinder, as: MoveFinder
  alias ChessQuo.GameTypes, as: Types
  alias ChessQuo.Chess.Piece, as: Piece
  alias ChessQuo.Chess.Game, as: Game

  def join(
        "room:" <> code,
        %{"params" => %{"current_game_role" => role, "current_game_secret" => secret}},
        socket
      ) do
    role = role_from_string(role)

    case load_and_authorize_lobby(code, role, secret) do
      {:ok, _} ->
        {:ok, assign(socket, :role, role) |> assign(:code, code)}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  @doc """
  Loads the lobby, and returns if the user is authorized. If the user is not authorized or loading the lobby fails,
  an error is returned.
  """
  @spec load_and_authorize_lobby(String.t(), Types.player_type(), String.t()) ::
          {:ok, Lobby.t()} | {:error, atom()}
  defp load_and_authorize_lobby(code, role, secret) do
    case Lobby.load(code) do
      {:ok, lobby} ->
        if player_secret(lobby, role) == secret do
          {:ok, lobby}
        else
          {:error, :not_authorized}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Extracts the secret for the specified role.
  """
  @spec player_secret(Lobby.t(), Types.player_type()) :: String.t()
  defp player_secret(%Lobby{host_secret: host_secret}, :host), do: host_secret
  defp player_secret(%Lobby{guest_secret: guest_secret}, _role), do: guest_secret

  @doc """
  Extracts the player's color based on their role.
  """
  @spec player_color(Lobby.t(), Types.player_type()) :: Types.color()
  defp player_color(%Lobby{host_color: color}, :host), do: color
  defp player_color(%Lobby{host_color: :white}, _), do: :black
  defp player_color(%Lobby{host_color: :black}, _), do: :white

  def handle_in("get_game_state", _, socket) do
    code = socket.assigns[:code]

    # Get the game state
    case Lobby.load(code) do
      {:ok, lobby} ->
        {:reply, {:ok, Poison.encode!(lobby.game)}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("get_valid_moves", params, socket) do
    code = socket.assigns[:code]
    board_index = params["board_index"]

    case Lobby.load(code) do
      {:ok, lobby} ->
        unless is_valid_board_index?(board_index) do
          {:reply, {:error, %{reason: "invalid_board_index"}}, socket}
        else
          valid_moves = MoveFinder.find_valid_moves(lobby.game)
          piece_moves = Enum.filter(valid_moves, fn move -> move.from == board_index end)

          # Encode the moves into JSON to send to the client
          piece_moves_json = Enum.map(piece_moves, &Poison.encode!/1)

          {:reply, {:ok, piece_moves_json}, socket}
        end

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("make_move", params, socket) do
    code = socket.assigns[:code]
    role = socket.assigns[:role]
    from = params["from"]
    to = params["to"]
    promote_to = Piece.string_to_piece(params["promote_to"])

    is_valid_input =
      Enum.all?([
        is_valid_board_index?(from),
        is_valid_board_index?(to),
        promote_to == nil
      ])

    if is_valid_input do
      case Lobby.load(code) do
        # Handle the case where a draw has been requested
        {:ok, %Lobby{draw_request_by: draw_request_by}} when not is_nil(draw_request_by) ->
          {:reply, {:error, %{reason: :draw_requested}}, socket}

        # Handle a game which is not ongoing
        {:ok, %Lobby{game: %Game{status: status}}} when status != :ongoing ->
          {:reply, {:error, %{reason: :game_not_ongoing}}, socket}

        # Handle a game where a move can be made by one player
        {:ok, %Lobby{game: %Game{turn: turn}} = lobby} ->
          # Make sure it's the requesting player's turn
          if player_color(lobby, role) == turn do
            # It's the players move
            process_move(lobby, from, to, promote_to, turn, socket)
          else
            {:reply, {:error, %{reason: :invalid_turn}}, socket}
          end

        {:error, reason} ->
          {:reply, {:error, %{reason: reason}}, socket}
      end
    else
      {:reply, {:error, %{reason: :invalid_input}}, socket}
    end
  end

  def handle_in("request_draw", _params, socket) do
    # Ask the other player if they want to draw
    code = socket.assigns[:code]
    role = socket.assigns[:role]

    with {:ok, lobby} <- Lobby.load(code),
         :ok <- Lobby.save(%Lobby{lobby | draw_request_by: role}) do
      broadcast!(socket, "draw_requested", %{role: role})
      {:reply, {:ok, true}, socket}
    else
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("accept_draw", _params, socket) do
    code = socket.assigns[:code]
    role = socket.assigns[:role]
    opposite_role = if role == :host, do: :guest, else: :host

    case Lobby.load(code) do
      {:ok, lobby} ->
        case lobby.draw_request_by do
          nil ->
            {:reply, {:error, %{reason: :no_draw_request}}, socket}

          ^role ->
            {:reply, {:error, %{reason: :cannot_accept_own_draw}}, socket}

          ^opposite_role ->
            end_game(lobby, :draw, socket)
        end

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("deny_draw", _params, socket) do
    code = socket.assigns[:code]
    role = socket.assigns[:role]

    with {:ok, lobby} <- Lobby.load(code),
         :ok <- Lobby.save(%Lobby{lobby | draw_request_by: nil}) do
      broadcast!(socket, "draw_denied", %{role: role})

      {:reply, {:ok, true}, socket}
    else
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("resign", _params, socket) do
    code = socket.assigns[:code]
    role = socket.assigns[:role]

    # End the game with the other player winning
    opposite_role = if role == :host, do: :guest, else: :host

    case Lobby.load(code) do
      {:ok, lobby} ->
        # Attribute the victory to the opposite player
        status = String.to_existing_atom("#{player_color(lobby, opposite_role)}_victory")
        end_game(lobby, status, socket)

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  defp process_move(lobby, from, to, promote_to, color, socket) do
    valid_moves = ChessQuo.Chess.MoveFinder.find_valid_moves(lobby.game)

    case find_move(valid_moves, color, from, to, promote_to) do
      {:ok, move} ->
        apply_and_broadcast_move(lobby, move, color, socket)

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  defp find_move(valid_moves, color, from, to, promote_to) do
    case Enum.find(valid_moves, fn move ->
           move.from == from and move.to == to and move.promote_to == promote_to and
             move.piece.color == color
         end) do
      nil ->
        {:error, :invalid_move}

      move ->
        {:ok, move}
    end
  end

  defp apply_and_broadcast_move(lobby, move, color, socket) do
    game = Game.apply_move(lobby.game, move)
    lobby = %Lobby{lobby | game: game}

    case Lobby.save(lobby) do
      :ok ->
        broadcast!(socket, "game_state_updated", %{game: Poison.encode!(game)})

        # Check the game condition
        game_condition = MoveFinder.game_condition(game)

        case game_condition do
          :checkmate ->
            status = String.to_existing_atom("#{color}_victory")
            end_game(lobby, status, socket)

          :stalemate ->
            end_game(lobby, :draw, socket)

          _ ->
            nil
        end

        {:reply, {:ok, Poison.encode!(game)}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  defp end_game(lobby, status, socket) do
    lobby = %Lobby{lobby | game: %Game{lobby.game | status: status}}

    case Lobby.save(lobby) do
      :ok ->
        broadcast!(socket, "game_over", %{message: game_over_message(status)})
        {:reply, {:ok, true}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  defp role_from_string("host"), do: :host
  defp role_from_string(_), do: :guest

  defp game_over_message(:draw), do: "Draw"
  defp game_over_message(:white_victory), do: "White wins!"
  defp game_over_message(:black_victory), do: "Black wins!"

  defp is_valid_board_index?(board_index) do
    board_index in 0..63
  end
end
