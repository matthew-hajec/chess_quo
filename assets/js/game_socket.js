import { Socket } from "phoenix";

const PIECE_IMAGES = {
  white: {
    king: "https://upload.wikimedia.org/wikipedia/commons/4/42/Chess_klt45.svg",
    queen:
      "https://upload.wikimedia.org/wikipedia/commons/1/15/Chess_qlt45.svg",
    rook: "https://upload.wikimedia.org/wikipedia/commons/7/72/Chess_rlt45.svg",
    bishop:
      "https://upload.wikimedia.org/wikipedia/commons/b/b1/Chess_blt45.svg",
    knight:
      "https://upload.wikimedia.org/wikipedia/commons/7/70/Chess_nlt45.svg",
    pawn: "https://upload.wikimedia.org/wikipedia/commons/4/45/Chess_plt45.svg",
  },
  black: {
    king: "https://upload.wikimedia.org/wikipedia/commons/f/f0/Chess_kdt45.svg",
    queen:
      "https://upload.wikimedia.org/wikipedia/commons/4/47/Chess_qdt45.svg",
    rook: "https://upload.wikimedia.org/wikipedia/commons/f/ff/Chess_rdt45.svg",
    bishop:
      "https://upload.wikimedia.org/wikipedia/commons/9/98/Chess_bdt45.svg",
    knight:
      "https://upload.wikimedia.org/wikipedia/commons/e/ef/Chess_ndt45.svg",
    pawn: "https://upload.wikimedia.org/wikipedia/commons/c/c7/Chess_pdt45.svg",
  },
};

// Loads the images into the browser cache
function preloadImages() {
  for (const color in PIECE_IMAGES) {
    for (const piece in PIECE_IMAGES[color]) {
      const img = new Image();
      img.src = PIECE_IMAGES[color][piece];
    }
  }
}

preloadImages(); // Preload on every page, if they are cached, this will not require a network request

function isGamePage() {
  return window.location.pathname.includes("/play/");
}

if (isGamePage()) {
  function parseCookies() {
    return document.cookie.split(";").reduce((cookies, cookie) => {
      const [name, value] = cookie.split("=").map((c) => c.trim());
      cookies[name] = value;
      return cookies;
    }, {});
  }

  function connectToGame(params) {
    return new Promise((resolve, reject) => {
      const socket = new Socket("/socket");
      socket.connect();

      const channel = socket.channel(`room:${params.current_game_code}`, {
        params,
      });
      channel
        .join()
        .receive("ok", (resp) => {
          resolve(channel);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function getGameState(channel) {
    return new Promise((resolve, reject) => {
      channel
        .push("get_game_state", {})
        .receive("ok", (resp) => {
          // Parse the game state from JSON
          const gameState = JSON.parse(resp);
          resolve(gameState);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function getValidMoves(channel, squareIndex) {
    return new Promise((resolve, reject) => {
      channel
        .push("get_valid_moves", { board_index: squareIndex })
        .receive("ok", (resp) => {
          parsedMoves = resp.map((move) => JSON.parse(move));
          resolve(parsedMoves);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function makeMove(channel, fromIndex, toIndex, promoteTo) {
    return new Promise((resolve, reject) => {
      channel
        .push("make_move", {
          from: fromIndex,
          to: toIndex,
          promote_to: promoteTo,
        })
        .receive("ok", (resp) => {
          resolve(resp);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function requestDraw(channel) {
    return new Promise((resolve, reject) => {
      channel
        .push("request_draw", {})
        .receive("ok", (resp) => {
          resolve(resp);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function acceptDraw(channel) {
    return new Promise((resolve, reject) => {
      channel
        .push("accept_draw", {})
        .receive("ok", (resp) => {
          resolve(resp);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function denyDraw(channel) {
    return new Promise((resolve, reject) => {
      channel
        .push("deny_draw", {})
        .receive("ok", (resp) => {
          resolve(resp);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function resign(channel) {
    return new Promise((resolve, reject) => {
      channel
        .push("resign", {})
        .receive("ok", (resp) => {
          resolve(resp);
        })
        .receive("error", (resp) => {
          reject(resp);
        });
    });
  }

  function closeLoader() {
    const loaderElem = document.querySelector("#loader");
    loaderElem.style.display = "none";
  }

  function renderGameState(gameState) {
    const turnIndicatorElem = document.querySelector("#current-turn");
    turnIndicatorElem.textContent = gameState.turn;

    for (let i = 0; i < gameState.board.length; i++) {
      const piece = gameState.board[i];
      const squareElem = document.querySelector(`[data-square-index="${i}"]`);

      // If the square has a color class (black or white), remove it
      squareElem.classList.remove("black");
      squareElem.classList.remove("white");

      // Remove any existing pieces from the square
      squareElem.innerHTML = "";

      // If there's a piece on the square, render it
      if (piece) {
        img_url = PIECE_IMAGES[piece.color][piece.piece];

        const imgElem = document.createElement("img");
        imgElem.src = img_url;
        imgElem.alt = `${piece.color} ${piece.type}`;
        imgElem.style.width = "75%";
        imgElem.style.height = "75%";

        squareElem.appendChild(imgElem);

        // Additionally, add a class to the square for the piece color
        squareElem.classList.add(piece.color);
      }
    }
  }

  // Can raise error if getValidMoves fails
  async function findAndHighlightValidMoves(channel, squareIndex) {
    const validMoves = await getValidMoves(channel, squareIndex);
    validMoves.forEach((move) => {
      const squareElem = document.querySelector(
        `[data-square-index="${move.to}"]`
      );
      squareElem.classList.add("valid-move");

      // If the move is a promotion, add a promotion class
      if (move.promote_to) {
        squareElem.classList.add("promotion");
      }
    });
  }

  function removeAllSquareHighlights() {
    const squares = document.querySelectorAll("[data-square-index]");
    squares.forEach((square) => {
      square.classList.remove("valid-move");
      square.classList.remove("selected");
      square.classList.remove("promotion");
    });
  }

  // Queries the player for the piece to promote to
  // Returns a string representing the piece to promote to
  function queryPromotionPiece() {
    const promotionMenuElem = document.getElementById("promotion-menu");
    promotionMenuElem.style.display = "flex";

    return new Promise((resolve, reject) => {
      function onClick(event) {
        const promotionButton = event.target.closest(".promotion-button");
        if (!promotionButton) {
          return;
        }

        const piece = promotionButton.getAttribute("data-piece");
        promotionMenuElem.style.display = "none";
        document.removeEventListener("click", onClick);
        resolve(piece);
      }

      document.addEventListener("click", onClick);
    });
  }

  // Queries the player for confirmation
  // Returns a boolean representing the player's choice (true for yes, false for no)
  function queryConfirmation(header, message) {
    const confirmationMenuElem = document.getElementById("confirmation-menu");
    const confirmationHeaderElem = document.getElementById(
      "confirmation-header"
    );
    const confirmationMessageElem = document.getElementById(
      "confirmation-message"
    );

    confirmationHeaderElem.textContent = header;
    confirmationMessageElem.textContent = message;

    confirmationMenuElem.style.display = "flex";

    return new Promise((resolve, reject) => {
      function onClick(event) {
        const confirmationButton = event.target.closest(".confirmation-button");
        if (!confirmationButton) {
          return;
        }

        const choice = confirmationButton.getAttribute("data-choice");
        confirmationMenuElem.style.display = "none";
        document.removeEventListener("click", onClick);
        resolve(choice === "yes");
      }

      document.addEventListener("click", onClick);
    });
  }

  function showNotification(header, message, is_closeable) {
    const notificationMenuElem = document.getElementById("notification-menu");
    const notificationHeaderElem = document.getElementById(
      "notification-header"
    );
    const notificationMessageElem = document.getElementById(
      "notification-message"
    );
    const notificationControlElem = document.getElementById(
      "notification-control"
    );
    const notificationCloseButtonElem =
      document.getElementById("notification-close");

    if (!is_closeable) {
      // If the notification is not closeable, hide the close button
      notificationControlElem.style.display = "none";
    } else {
      // Otherwise, show the close button and handle closing
      notificationControlElem.style.display = "flex";
      function onClick(event) {
        notificationMenuElem.style.display = "none";
        document.removeEventListener("click", onClick);
      }
      notificationCloseButtonElem.addEventListener("click", onClick);
    }

    notificationHeaderElem.textContent = header;
    notificationMessageElem.textContent = message;

    notificationMenuElem.style.display = "flex";
  }

  // Wrapper for game logic using async/await
  async function main() {
    const cookies = parseCookies();
    const playerColor = cookies.current_game_color;
    const playerRole = cookies.current_game_role;

    // State variables
    let currentlySelectedSquare = null; // Index of the currently selected square, if any, else null

    const channel = await connectToGame(cookies);
    const gameState = await getGameState(channel);
    closeLoader();
    renderGameState(gameState);

    // Handler for when the game state is updated
    channel.on("game_state_updated", async (resp) => {
      const gameState = JSON.parse(resp.game);
      renderGameState(gameState);
    });

    // Handler for when the game is over
    channel.on("game_over", async (resp) => {
      // Display a notification with the game result
      showNotification("Game Over", resp.message, true);
    });

    // Handler for when the opponent has requested a draw
    channel.on("draw_requested", async (resp) => {
      const isOpponent = resp.role !== playerRole;
      if (!isOpponent) {
        return;
      }

      const confirmed = await queryConfirmation(
        "Draw Request",
        "Your opponent has requested a draw. Do you accept?"
      );
      if (confirmed) {
        await acceptDraw(channel);
      } else {
        await denyDraw(channel);
      }
    });

    // Handler for when a square is clicked
    document.addEventListener("click", async (event) => {
      // Find the square that was clicked
      const squareElem = event.target.closest("[data-square-index]");
      if (!squareElem) {
        return;
      }

      // Get the index of the square that was clicked
      const squareIndex = parseInt(
        squareElem.getAttribute("data-square-index")
      );

      // Determine if the square is a valid move from the currently selected square
      const isValidMove = squareElem.classList.contains("valid-move");

      // If no square is selected, select the clicked square
      if (isValidMove) {
        // Check if the clicked square is a promotion move
        const isPromotion = squareElem.classList.contains("promotion");

        if (isPromotion) {
          // If it's a promotion move, query the player for the piece to promote to
          const promotionPiece = await queryPromotionPiece();
          await makeMove(
            channel,
            currentlySelectedSquare,
            squareIndex,
            promotionPiece
          );
        } else {
          // If it's a regular move, make the move
          await makeMove(channel, currentlySelectedSquare, squareIndex);
        }

        // Unselect the currently selected square
        removeAllSquareHighlights();
        currentlySelectedSquare = null;
      } else {
        // Unselect the currently selected square
        removeAllSquareHighlights();
        currentlySelectedSquare = null;

        // If the square has a piece of the player's color, select it
        if (squareElem.classList.contains(playerColor)) {
          currentlySelectedSquare = squareIndex;
          squareElem.classList.add("selected");
          await findAndHighlightValidMoves(channel, squareIndex);
        }
      }
    });

    const resignButtonElem = document.getElementById("resign-button");
    resignButtonElem.addEventListener("click", async (event) => {
      const confirmed = await queryConfirmation(
        "Resign Game",
        "Are you sure you want to resign?"
      );
      if (confirmed) {
        await resign(channel);
      }
    });

    const drawButtonElem = document.getElementById("draw-button");
    drawButtonElem.addEventListener("click", async (event) => {
      const confirmed = await queryConfirmation(
        "Request Draw",
        "Are you sure you want to request a draw?"
      );
      if (confirmed) {
        await requestDraw(channel);
      }
    });
  }

  // Run the game logic
  main();
}
