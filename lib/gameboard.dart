import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/pieces.dart';
import 'package:flutter_tetris/pixels.dart';
import 'package:flutter_tetris/values.dart';

/*
GAME BOARD
This is 2X2 grid with null representing an empty space.
A non empty space will have the color to represent the landed pieces.
 */

//creating game board
List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(
    rowLength,
    (j) => null,
  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  //current Tetris piece
  Piece currentPiece = Piece(type: Tetromino.L);
  int currentScore = 0;
  //game over status
  bool gameOver = false;

  @override
  void initState() {
    super.initState();

    //Start the game when app starts
    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();
    Duration frameRate = const Duration(milliseconds: 500);
    gameLoop(frameRate);
  }

  //game loop
  void gameLoop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        //clear the lines
        clearLines();

        //check landing
        checkLanding();

        //check if the game is Over
        if (gameOver == true) {
          timer.cancel();
          gameOverDialog();
        }

        //move current piece down
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  //gameOverMessage
  void gameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Game Over!'),
        content: Text('Your score is : $currentScore'),
        actions: [
          TextButton(
              onPressed: () {
                //reset the game again!
                resetGame();
                Navigator.pop(context);
              },
              child: Text('Play Again')),
        ],
      ),
    );
  }

  //reset game method
  void resetGame() {
    //clear the gameBoard
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(
        rowLength,
        (j) => null,
      ),
    );
    //new Game
    gameOver = false;
    currentScore = 0;

    //create new piece
    createNewPiece();

    //start game again
    startGame();
  }

  //collision detection in a future position
  //return true if there is a collision
  //return false if there is no collision
  bool checkCollision(Direction direction) {
    //loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      //calculate the row and column  of the current position
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      //adjust the row and column based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      //check the piece if it is out of bounce(either too low or to far from the left or right)
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }
      // Check if the future position collides with any landed pieces
      if (row >= 0 && col >= 0 && gameBoard[row][col] != null) {
        return true;
      }
    }
    // if no collision is detected then return false
    return false;
  }

  //check landing
  void checkLanding() {
    //if going down is completed
    if (checkCollision(Direction.down)) {
      //mark position as occupied
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }
      // once landed create a new piece
      createNewPiece();
    }
  }

  void createNewPiece() {
    // create a random object to create a random tetromino type
    Random rand = Random();
    //create a new random tetromino piece
    Tetromino randomType =
        Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();
    /*
    Since our game condition is if there is a top piece at the top level,
    you want to check if the game is over when you create a new piece,
    instead checking every frame, because new pieces are allowed to go through the top level,
    but there is a piece when new piece is created then game is over.
    */
    if (isGameOver()) {
      gameOver = true;
    }
  }

  //move left
  void moveLeft() {
    //make sure the move is valid before collision
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  //rotate piece
  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  //move right
  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  //clear lines method
  void clearLines() {
    // step 1: loop through each row of the game fro bottom to top
    for (int row = colLength - 1; row >= 0; row--) {
      //step 2: initialize the variable to check if the row is full
      bool rowIsFull = true;

      //check if the row is full, all columns are filled with pieces
      for (int col = 0; col < rowLength; col++) {
        // if there is an empty column, set rowIsFul to false and break the loop
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }
      //step 4: if the row is ful we can clear the row and shift them down
      if (rowIsFull) {
        // step 5: move all row above the cleared row down by one position
        for (int r = row; r > 0; r--) {
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }
        // step 6: set the top row to empty
        gameBoard[0] = List.generate(row, (index) => null);

        //step 7: increase the score
        currentScore++;
      }
    }
  }

  //Game over method
  bool isGameOver() {
    //check if the column at the top is filled
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }
    // if the top row is empty, the game is not over
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: rowLength * colLength,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rowLength,
              ),
              itemBuilder: (context, index) {
                //get row and column of each index
                int row = (index / rowLength).floor();
                int col = index % rowLength;

                if (currentPiece.position.contains(index)) {
                  //current piece
                  return Pixel(
                    color: currentPiece.color,
                  );
                }
                //landed pieces
                else if (gameBoard[row][col] != null) {
                  final Tetromino? tetrominoType = gameBoard[row][col];
                  return Pixel(
                    color: tetrominoColors[tetrominoType],
                  );
                } else {
                  //blank pixel
                  return Pixel(
                    color: Colors.grey.shade900,
                  );
                }
              },
            ),
          ),

          //SCORE
          Text(
            'SCORE : $currentScore',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          //Some Game Controllers

          Padding(
            padding: const EdgeInsets.only(bottom: 50.0, top: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: moveLeft,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                  ),
                ),

                //rotate
                IconButton(
                  onPressed: rotatePiece,
                  icon: Icon(
                    Icons.rotate_right,
                    color: Colors.white,
                  ),
                ),
                //right
                IconButton(
                  onPressed: moveRight,
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
          //left
        ],
      ),
    );
  }
}
