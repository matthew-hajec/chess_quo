defmodule ChessQuo.GameTypes do
  @moduledoc """
  Shared types for game and lobby related modules.
  """
  # Define the atoms so that String.to_existing_atom does not fail.
  _ = [
    :white, :black, :pawn, :rook, :knight, :bishop, :queen, :king, :host, :guest, :ongoing, :white_victory, :black_victory, :draw
  ]

  @type color :: :white | :black
  @type piece_type :: :pawn | :rook | :knight | :bishop | :queen | :king
  @type player_type :: :host | :guest
  @type castle_side :: :king | :queen
  @type game_status :: :ongoing | :white_victory | :black_victory | :draw
end
