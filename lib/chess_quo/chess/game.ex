defmodule ChessQuo.Chess.Game do
  @moduledoc """
  Definition and functions for interacting with a game.
  """

  alias ChessQuo.Chess.Game, as: Game
  alias ChessQuo.Chess.Piece, as: Piece
  alias ChessQuo.Chess.Move, as: Move
  alias ChessQuo.GameTypes, as: Types

  @type t :: %Game{
          turn: Types.color(),
          # 64 elements, nil represents empty
          board: [Piece.t() | nil],
          previous_move: Move.t() | nil,
          move_history: [Move.t()],
          status: Types.game_status()
        }

  @derive Poison.Encoder
  defstruct turn: :white,
            board:
              [
                # White's Back Rank
                %Piece{color: :white, piece: :rook},
                %Piece{color: :white, piece: :knight},
                %Piece{color: :white, piece: :bishop},
                %Piece{color: :white, piece: :queen},
                %Piece{color: :white, piece: :king},
                %Piece{color: :white, piece: :bishop},
                %Piece{color: :white, piece: :knight},
                %Piece{color: :white, piece: :rook},

                # White's Pawns
                %Piece{color: :white, piece: :pawn},
                %Piece{color: :white, piece: :pawn},
                %Piece{color: :white, piece: :pawn},
                %Piece{color: :white, piece: :pawn},
                %Piece{color: :white, piece: :pawn},
                %Piece{color: :white, piece: :pawn},
                %Piece{color: :white, piece: :pawn},
                %Piece{color: :white, piece: :pawn}
              ] ++
                List.duplicate(nil, 32) ++
                [
                  # Black's Pawns
                  %Piece{color: :black, piece: :pawn},
                  %Piece{color: :black, piece: :pawn},
                  %Piece{color: :black, piece: :pawn},
                  %Piece{color: :black, piece: :pawn},
                  %Piece{color: :black, piece: :pawn},
                  %Piece{color: :black, piece: :pawn},
                  %Piece{color: :black, piece: :pawn},
                  %Piece{color: :black, piece: :pawn},

                  # Black's Back Rank
                  %Piece{color: :black, piece: :rook},
                  %Piece{color: :black, piece: :knight},
                  %Piece{color: :black, piece: :bishop},
                  %Piece{color: :black, piece: :queen},
                  %Piece{color: :black, piece: :king},
                  %Piece{color: :black, piece: :bishop},
                  %Piece{color: :black, piece: :knight},
                  %Piece{color: :black, piece: :rook}
                ],
            previous_move: nil,
            move_history: [],
            status: :ongoing

  defimpl Poison.Decoder do
    def decode(
          %Game{
            turn: turn,
            board: board,
            previous_move: previous_move,
            move_history: move_history,
            status: status
          },
          _opts
        ) do
      board =
        Enum.map(board, fn piece ->
          if piece == nil do
            nil
          else
            Poison.decode!(Poison.encode!(piece), as: %Piece{})
          end
        end)

      turn = String.to_existing_atom(turn)

      previous_move =
        if previous_move == nil do
          nil
        else
          Poison.decode!(Poison.encode!(previous_move), as: %Move{})
        end

      move_history =
        Enum.map(move_history, fn move ->
          Poison.decode!(Poison.encode!(move), as: %Move{})
        end)

      status =
        if is_binary(status) do
          String.to_existing_atom(status)
        else
          status
        end

      %Game{
        turn: turn,
        board: board,
        previous_move: previous_move,
        move_history: move_history,
        status: status
      }
    end
  end

  @doc """
  Creates a new game state.
  """
  @spec new() :: Game.t()
  def new do
    %Game{}
  end

  @spec at(Game.t(), non_neg_integer()) :: Piece.t() | nil
  def at(game, index) when index >= 0 and index <= 63 do
    Enum.at(game.board, index)
  end

  def at(_game, index) do
    raise ArgumentError, "Invalid board index=#{index}. Index must be between 0 and 63 inclusive."
  end

  @spec apply_move(Game.t(), Move.t()) :: Game.t()
  def apply_move(game, move) do
    game =
      game
      |> apply_castle_to_rook(move)
      |> apply_capture(move)
      |> apply_pawn_promotion(move)

    # Piece may have been changed by promotion
    piece = Enum.at(game.board, move.from)

    board =
      List.replace_at(game.board, move.from, nil)
      |> List.replace_at(move.to, piece)

    move_history = [move | game.move_history]

    %Game{
      game
      | board: board,
        turn: next_turn(game.turn),
        previous_move: move,
        move_history: move_history
    }
  end

  @spec end_game(Game.t(), Types.game_status()) :: Game.t()
  def end_game(game, game_status) do
    %Game{game | status: game_status}
  end

  @spec apply_castle_to_rook(Game.t(), Move.t()) :: Game.t()
  defp apply_castle_to_rook(game, move) do
    king_start_idx = move.from

    # If the move is a castle move, move the rook as well
    case move.castle_side do
      nil ->
        game

      :king ->
        rook_start_idx = king_start_idx + 3
        rook_end_idx = king_start_idx + 1
        rook = Enum.at(game.board, rook_start_idx)

        board = List.replace_at(game.board, rook_start_idx, nil)
        board = List.replace_at(board, rook_end_idx, rook)
        %Game{game | board: board}

      :queen ->
        rook_start_idx = king_start_idx - 4
        rook_end_idx = king_start_idx - 1
        rook = Enum.at(game.board, rook_start_idx)

        board = List.replace_at(game.board, rook_start_idx, nil)
        board = List.replace_at(board, rook_end_idx, rook)
        %Game{game | board: board}
    end
  end

  @spec apply_capture(Game.t(), Move.t()) :: Game.t()
  defp apply_capture(game, move) do
    if move.captures != nil do
      board = List.replace_at(game.board, move.captures, nil)
      %Game{game | board: board}
    else
      game
    end
  end

  @spec apply_pawn_promotion(Game.t(), Move.t()) :: Game.t()
  defp apply_pawn_promotion(game, move) do
    if move.promote_to != nil do
      piece = Enum.at(game.board, move.from)
      piece = %Piece{piece | piece: move.promote_to}

      board = List.replace_at(game.board, move.from, piece)
      %Game{game | board: board}
    else
      game
    end
  end

  defp next_turn(:white), do: :black
  defp next_turn(:black), do: :white
end
