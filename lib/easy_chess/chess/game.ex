defmodule EasyChess.Chess.Game do
  alias EasyChess.Chess.{Piece, Move}

  @derive Poison.Encoder
  defstruct turn: :white,

            # 64 elements, 0-7 is the first row, 8-15 is the second row, etc.
            # Ranks 3-6 (Empty Squares)
            board:
              [
                # Rank 1 (White's Back Rank)
                # a1
                %Piece{color: :white, piece: :rook},
                # b1
                %Piece{color: :white, piece: :knight},
                # c1
                %Piece{color: :white, piece: :bishop},
                # d1
                %Piece{color: :white, piece: :queen},
                # e1
                %Piece{color: :white, piece: :king},
                # f1
                %Piece{color: :white, piece: :bishop},
                # g1
                %Piece{color: :white, piece: :knight},
                # h1
                %Piece{color: :white, piece: :rook},

                # Rank 2 (White's Pawns)
                # a2
                %Piece{color: :white, piece: :pawn},
                # b2
                %Piece{color: :white, piece: :pawn},
                # c2
                %Piece{color: :white, piece: :pawn},
                # d2
                %Piece{color: :white, piece: :pawn},
                # e2
                %Piece{color: :white, piece: :pawn},
                # f2
                %Piece{color: :white, piece: :pawn},
                # g2
                %Piece{color: :white, piece: :pawn},
                # h2
                %Piece{color: :white, piece: :pawn}
              ] ++
                List.duplicate(nil, 32) ++
                [
                  # Rank 7 (Black's Pawns)
                  # a7
                  %Piece{color: :black, piece: :pawn},
                  # b7
                  %Piece{color: :black, piece: :pawn},
                  # c7
                  %Piece{color: :black, piece: :pawn},
                  # d7
                  %Piece{color: :black, piece: :pawn},
                  # e7
                  %Piece{color: :black, piece: :pawn},
                  # f7
                  %Piece{color: :black, piece: :pawn},
                  # g7
                  %Piece{color: :black, piece: :pawn},
                  # h7
                  %Piece{color: :black, piece: :pawn},

                  # Rank 8 (Black's Back Rank)
                  # a8
                  %Piece{color: :black, piece: :rook},
                  # b8
                  %Piece{color: :black, piece: :knight},
                  # c8
                  %Piece{color: :black, piece: :bishop},
                  # d8
                  %Piece{color: :black, piece: :queen},
                  # e8
                  %Piece{color: :black, piece: :king},
                  # f8
                  %Piece{color: :black, piece: :bishop},
                  # g8
                  %Piece{color: :black, piece: :knight},
                  # h8
                  %Piece{color: :black, piece: :rook}
                ],
            previous_move: nil,
            move_history: []

  defimpl Poison.Decoder do
    def decode(
          %EasyChess.Chess.Game{
            turn: turn,
            board: board,
            previous_move: previous_move,
            move_history: move_history
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

      %EasyChess.Chess.Game{
        turn: turn,
        board: board,
        previous_move: previous_move,
        move_history: move_history
      }
    end
  end

  @doc """
  Creates a new game state.
  """
  def new do
    %EasyChess.Chess.Game{}
  end

  def at(game, index) when index >= 0 and index <= 63 do
    Enum.at(game.board, index)
  end

  def at(_game, index) do
    raise ArgumentError, "Invalid board index=#{index}. Index must be between 0 and 63 inclusive."
  end

  def apply_move(game, move) do
    new_board = apply_castle_to_rook(game.board, move)
    new_board = apply_capture(new_board, move)
    new_board = apply_pawn_promotion(new_board, move)

    # Move the piece
    # Piece may have been changed by promotion
    piece = Enum.at(new_board, move.from)
    new_board = List.replace_at(new_board, move.from, nil)
    new_board = List.replace_at(new_board, move.to, piece)

    move_history = [move | game.move_history]

    %EasyChess.Chess.Game{
      game
      | board: new_board,
        turn: next_turn(game.turn),
        previous_move: move,
        move_history: move_history
    }
  end

  defp apply_castle_to_rook(board, move) do
    # If the move is a castle move, move the rook as well
    # Returns a new board
    if move.castle_side != nil do
      king_start_idx = move.from

      if move.castle_side == :king do
        rook_start_idx = king_start_idx + 3
        rook_end_idx = king_start_idx + 1
        rook = Enum.at(board, rook_start_idx)

        new_board = List.replace_at(board, rook_start_idx, nil)
        List.replace_at(new_board, rook_end_idx, rook)
      else
        rook_start_idx = king_start_idx - 4
        rook_end_idx = king_start_idx - 1
        rook = Enum.at(board, rook_start_idx)

        new_board = List.replace_at(board, rook_start_idx, nil)
        List.replace_at(new_board, rook_end_idx, rook)
      end
    else
      # Return the original board when not castling
      board
    end
  end

  defp apply_capture(board, move) do
    if move.captures != nil do
      List.replace_at(board, move.captures, nil)
    else
      board
    end
  end

  # This promotes the piece, but does not move it.
  # This works because apply_move/2 does not validate moves, so the piece will be moved
  defp apply_pawn_promotion(board, move) do
    if move.promote_to != nil do
      piece = Enum.at(board, move.from)
      piece = %Piece{piece | piece: move.promote_to}

      List.replace_at(board, move.from, piece)
    else
      board
    end
  end

  defp next_turn(:white), do: :black
  defp next_turn(:black), do: :white
end
