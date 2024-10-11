defmodule EasyChess.Chess.MoveFinder.Helpers do
  alias EasyChess.Chess.MoveFinder
  alias EasyChess.Chess.Piece

  def in_bounds?(index) do
    index >= 0 and index <= 63
  end

  def rank_and_file(index) do
    {div(index, 8), rem(index, 8)}
  end

  def index(rank, file) do
    rank * 8 + file
  end

  def valid_rank?(rank) do
    rank >= 0 and rank <= 7
  end

  def valid_file?(file) do
    file >= 0 and file <= 7
  end

  def valid_position?(current_index, rank, file) do
    in_bounds?(current_index) and valid_rank?(rank) and valid_file?(file)
  end


  def king_in_check?(game, color) do
    # Find the index of the king of the given color
    king_index =
      Enum.find_index(game.board, fn piece ->
        piece == %Piece{piece: :king, color: color}
      end)

    # Generate all moves with the `validating` flag set to true
    # This prevents infinite recursion, since find_valid_moves must
    # check if the king is in check
    all_moves = MoveFinder.find_valid_moves(game, 0, [], true)

    # Filter moves to include only the opponent's moves
    opponent_moves =
      Enum.filter(all_moves, fn move ->
        move.piece.color != color
      end)

    # Check if any opponent move can attack the king's position
    Enum.any?(opponent_moves, fn move ->
      move.to == king_index
    end)
  end
end
