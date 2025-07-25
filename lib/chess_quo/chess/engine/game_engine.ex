defprotocol ChessQuo.GameEngine do
  @doc "Returns a list of valid moves"
  @spec valid_moves(t()) :: {:ok, list(ChessQuo.Chess.Move.t())} | {:error, atom()}
  def valid_moves(game)

  @doc "Returns the condition of the game"
  @spec game_condition(t()) :: :checkmate | :stalemate | :draw
  def game_condition(game)
end
