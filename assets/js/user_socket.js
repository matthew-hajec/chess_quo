import { Socket } from "phoenix";

// Check if the current page is a game page
function isGamePage() {
  return window.location.pathname.includes("/play/");
}

// Parse cookies into an object
function parseCookies() {
  return document.cookie.split(';').reduce((cookies, cookie) => {
    const [name, value] = cookie.split('=').map(c => c.trim());
    cookies[name] = value;
    return cookies;
  }, {});
}

if (isGamePage()) {
  const cookies = parseCookies();

  // Connect to the Phoenix socket with cookies for params
  const socket = new Socket("/socket", { params: cookies });
  socket.connect();

  // Join the game channel using the current game code from cookies
  const channel = socket.channel(`room:${cookies.current_game_code}`, { params: cookies });
  channel.join()
    .receive("ok", resp => console.log("Joined successfully", resp))
    .receive("error", resp => console.log("Unable to join", resp));

  let selectedSquareIdx = null;

  function loadGameState() {
    channel.push("get_game_state", {})
      .receive("ok", resp => {
        gameState = JSON.parse(resp);
        renderGameState(gameState);
      })
      .receive("error", resp => console.log("Unable to get game state", resp));
  }

  function renderGameState(gameState) {
    for (let i = 0; i < gameState.board.length; i++) {
      const piece = gameState.board[i];
      const square = document.querySelector(`[data-square-index="${i}"]`);
      if (square && piece) {
        console.log("Rendering piece", piece);
        square.innerHTML = `${piece.color} ${piece.piece}`;
      }
    }
  }

  // Unselect all squares and reset the selection index
  function unselectSquare() {
    const squares = document.querySelectorAll("[data-square-index]");
    squares.forEach(square => {
      square.classList.remove("valid-move");
      square.classList.remove("selected");
    });

    selectedSquareIdx = null;
  }

  // Select a square and highlight valid moves
  function selectSquare(squareIndex) {
    console.log("Selecting square", squareIndex)
    // Unselect previous square
    unselectSquare();

    // Request valid moves for the selected square
    channel.push("get_valid_moves", { board_index: parseInt(squareIndex) })
      .receive("ok", resp => {
        console.log("Valid moves", resp);
        selectedSquareIdx = squareIndex;
        const selectedSquare = document.querySelector(`[data-square-index="${squareIndex}"]`);
        if (selectedSquare) {
          selectedSquare.classList.add("selected");

          // Highlight valid moves
          resp.forEach(move => {
            // convert the JSON-serialized data to a JS object
            move = JSON.parse(move);

            // print the type of move
            console.log("data type of move", typeof move);

            console.log(move)
            console.log("Highlighting valid move", move.to);
            const square = document.querySelector(`[data-square-index="${move.to}"]`);
            if (square) {
              square.classList.add("valid-move");
            }
          });
        }
      })
      .receive("error", resp => console.log("Unable to get valid moves", resp));
  }

  // Load the game state when the page loads
  loadGameState();

  // Handle square click events
  document.addEventListener("click", ev => {
    const squareIndex = ev.target.getAttribute("data-square-index");

    if (squareIndex) {
      selectSquare(squareIndex);
    }
  });
}
