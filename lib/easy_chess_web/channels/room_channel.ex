defmodule EasyChessWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:" <> lobby_code, params, socket) do
    %{
      "current_game_role" => role,
      "current_game_secret" => secret
    } = params["params"]

    role = role_from_string(role)

    cond do
      !EasyChess.Lobby.lobby_exists?(lobby_code) ->
        {:error, %{reason: "lobby_not_found"}}

      !EasyChess.Lobby.is_valid_secret?(lobby_code, role, secret) ->
        {:error, %{reason: "unauthorized"}}

      true ->
        # Assign the role and lobby code to the socket
        socket =
          socket
          |> assign(:role, role)
          |> assign(:lobby_code, lobby_code)

        {:ok, socket}
    end
  end

  def handle_in("get_game_state", _, socket) do
    lobby_code = socket.assigns[:lobby_code]

    IO.inspect("Lobby code: #{lobby_code}")

    {:ok, game} = EasyChess.Chess.GamesManager.get_game_state(lobby_code)

    {:reply, {:ok, game}, socket}
  end

  defp role_from_string("host"), do: :host
  defp role_from_string(_), do: :guest
end
