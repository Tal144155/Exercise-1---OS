#!/bin/bash

# Function to check the number of arguments
check_argument_number() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <path_to_pgn_file>"
        exit 1
    fi
}

# Function to check if the file exists
check_file_exists() {
    if [ ! -f "$1" ]; then
        echo "File does not exist: $1"
        exit 1
    fi
}

# Function to parse the PGN file
parse_pgn() {
    metadata=$(grep -E '^\[.*\]$' "$1") # Extract metadata from PGN file
    moves=$(grep -v '^\[' "$1" | tr '\n' ' ') # Extract moves from PGN file and remove newlines

    echo "Metadata from PGN file:"
    echo "$metadata"
    echo ""

    uci_moves=($(python3 parse_moves.py "$moves")) # Parse moves using a Python script

    move_number=${#uci_moves[@]} # Get the total number of moves
}

# Function to initialize the chess board
initialize_board() {
    board[8]="r n b q k b n r" # Black pieces
    board[7]="p p p p p p p p" # Black pawns
    board[6]=". . . . . . . ." # Empty rows
    board[5]=". . . . . . . ."
    board[4]=". . . . . . . ."
    board[3]=". . . . . . . ."
    board[2]="P P P P P P P P" # White pawns
    board[1]="R N B Q K B N R" # White pieces
}

# Function to display the chess board
display_board() {
    echo "Move $1/$move_number"
    echo "  a b c d e f g h"
    for ((i=8; i>=1; i--)); do
        row="${board[i]}"
        echo "$i $row $i"
    done
    echo "  a b c d e f g h"
}

# Function to apply a move on the chess board
apply_move_on_board() {
    local move="$1"
    local from="${move:0:2}"
    local to="${move:2:2}"

    # Checking for promotion
    local promotion_piece=""

    if [ "${#move}" -eq 5 ]; then
        promotion_piece="${move:4:1}"
    fi

    local from_file=$(from_letter_to_number "${from:0:1}") # Convert file letter to number (a-h)
    local from_rank="${from:1:1}" # Get the rank (1-8)
    local to_file=$(from_letter_to_number "${to:0:1}") # Convert file letter to number (a-h)
    local to_rank="${to:1:1}" # Get the rank (1-8)
    local piece=$(get_piece "$from_file" "$from_rank") # Get the piece at the source position

    if [ -n "$promotion_piece" ]; then
        if [[ "$piece" =~ [P] ]]; then
            piece=$(echo "$promotion_piece" | tr 'a-z' 'A-Z') # Promote to uppercase if the piece is a white pawn
        else
            piece=$(echo "$promotion_piece" | tr 'A-Z' 'a-z') # Promote to lowercase if the piece is a black pawn
        fi
    fi

    # Handle castling
    if [[ "$piece" =~ [Kk] && "$((from_file - to_file))" -eq 2 ]]; then
        # Queenside castling
        set_piece "$((to_file + 1))" "$to_rank" "$(get_piece 1 $to_rank)" # Move the rook to the correct position
        set_piece 1 "$to_rank" "." # Clear the original rook position
    elif [[ "$piece" =~ [Kk] && "$((to_file - from_file))" -eq 2 ]]; then
        # Kingside castling
        set_piece "$((to_file - 1))" "$to_rank" "$(get_piece 8 $to_rank)" # Move the rook to the correct position
        set_piece 8 "$to_rank" "." # Clear the original rook position
    fi

    # Handle en passant
    if [[ "$piece" =~ [Pp] && "$from_file" -ne "$to_file" && "$(get_piece "$to_file" "$to_rank")" == "." ]]; then
        if [[ "$piece" =~ [P] ]]; then
            set_piece "$to_file" "$((to_rank - 1))" "." # Clear the captured pawn (white)
        else
            set_piece "$to_file" "$((to_rank + 1))" "." # Clear the captured pawn (black)
        fi
    fi

    set_piece "$from_file" "$from_rank" "." # Clear the source position
    set_piece "$to_file" "$to_rank" "$piece" # Set the piece at the destination position
}

# Function to get the piece at a specific position on the chess board
get_piece() {
    local file="$1"
    local rank="$2"
    local index=$(( (file-1)*2 ))
    echo "${board[rank]:$index:1}"
}

# Function to set the piece at a specific position on the chess board
set_piece() {
    local file="$1"
    local rank="$2"
    local piece="$3"
    local index=$(( (file-1)*2 ))
    board[rank]="${board[rank]:0:$index}$piece${board[rank]:$(($index+1))}"
}

# Function to convert file letter to number (a-h)
from_letter_to_number() {
    local file="$1"
    declare -A file_map=( [a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [g]=7 [h]=8 )
    echo "${file_map[$file]}"
}

# Function to handle the game loop
game_function_loop() {
    while true; do
        echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
        read -r key
        case "$key" in
            d)
                if [ $current_move -lt $move_number ]; then
                    apply_move_on_board "${uci_moves[$current_move]}" # Apply the move on the board
                    ((current_move++)) # Increment the current move counter
                    display_board $current_move # Display the updated board
                else
                    echo "No more moves available."
                fi
                ;;
            a)
                if [ $current_move -gt 0 ]; then
                    ((current_move--)) # Decrement the current move counter
                    initialize_board # Reset the board to the initial state
                    for ((i=0; i<current_move; i++)); do
                        apply_move_on_board "${uci_moves[$i]}" # Apply the moves up to the current move on the board
                    done
                fi
                display_board $current_move # Display the updated board
                ;;
            w)
                initialize_board # Reset the board to the initial state
                current_move=0 # Set the current move counter to 0
                display_board $current_move # Display the updated board
                ;;
            s)
                initialize_board # Reset the board to the initial state
                for move in "${uci_moves[@]}"; do
                    apply_move_on_board "$move" # Apply all the moves on the board
                done
                current_move=${#uci_moves[@]} # Set the current move counter to the total number of moves
                display_board $current_move # Display the updated board
                ;;
            q)
                echo "Exiting."
                echo "End of game."
                exit 0
                ;;
            *)
                echo "Invalid key pressed: $key"
                ;;
        esac
    done
}

# Main function
main() {
    check_argument_number "$@" # Check the number of arguments

    check_file_exists "$1" # Check if the file exists

    initialize_board # Initialize the chess board

    parse_pgn "$1" # Parse the PGN file

    current_move=0 # Initialize the current move counter
    display_board $current_move # Display the initial board

    game_function_loop # Start the game loop
}

main "$@" # Call the main function with command-line arguments
