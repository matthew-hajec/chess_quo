defmodule EasyChess.Chess.MoveFinder.Helpers do
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
end
