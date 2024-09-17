// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// Bring in Phoenix channels client library:
import {Socket} from "phoenix"

function isGamePage() {
  return window.location.pathname.includes("/play/")
}

function parseCookies() {
  return document.cookie.split(';').reduce((cookies, cookie) => {
    const [name, value] = cookie.split('=').map(c => c.trim());
    cookies[name] = value;
    return cookies;
  }, {});
}

console.log("isGamePage", isGamePage())
console.log(window.location.pathname)

// And connect to the path in "lib/easy_chess_web/endpoint.ex". We pass the
// token for authentication. Read below how it should be used.

if (isGamePage()) {
  cookies = parseCookies()

  // Connect to the socket
  let socket = new Socket("/socket", {params: cookies})
  socket.connect()

  // Join the game channel
  let channel = socket.channel(`room:${cookies.current_game_code}`, {params: cookies})
  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })


  channel.push("get_game_state", {})
    .receive("ok", resp => {
      console.log("Game state", resp)
    })
    .receive("error", resp => {
      console.log("Unable to get game state", resp)
    })

  channel.push("get_valid_moves", {board_index: 9})
    .receive("ok", resp => {
      console.log("Valid moves", resp)
    })
    .receive("error", resp => {
      console.log("Unable to get valid moves", resp)
    })

}

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/easy_chess_web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/easy_chess_web/templates/layout/app.html.heex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/easy_chess_web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
//socket.connect()

// Now that you are connected, you can join channels with a topic.
// Let's assume you have a channel with a topic named `room` and the
// subtopic is its id - in this case 42:
//let channel = socket.channel("room:42", {})
//channel.join()
  //.receive("ok", resp => { console.log("Joined successfully", resp) })
  //.receive("error", resp => { console.log("Unable to join", resp) })

