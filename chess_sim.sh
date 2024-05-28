#!/bin/bash

check_argument_number() {
    if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_pgn_file>"
    exit 1
    fi
}

check_file_exists() {
    if [ ! -f "$1" ]; then
    echo "File does not exist: $1"
    exit 1
    fi
}

parse_pgn() {
    metadata=$(grep -E '^\[.*\]$' "$1")
    moves=$(grep -v '^\[' "$1" | tr '\n' ' ')

    echo "Metadata from PGN file:"
    echo "$metadata"

    uci_moves=($(python3 parse_moves.py "$moves"))

    move_number=${#uci_moves[@]}

}

# Function to initialize the board
initialize_board() {
    board[8]="r n b q k b n r"
    board[7]="p p p p p p p p"
    board[6]=". . . . . . . ."
    board[5]=". . . . . . . ."
    board[4]=". . . . . . . ."
    board[3]=". . . . . . . ."
    board[2]="P P P P P P P P"
    board[1]="R N B Q K B N R"
}

display_board() {
    echo "Move $1/$move_number"
    echo "  a b c d e f g h"
    for ((i=8; i>=1; i--)); do
        row="${board[i]}"
        echo "$i $row $i"
    done
    echo "  a b c d e f g h"
    echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
}

# Function to apply a UCI move to the board
apply_uci_move() {
    local move="$1"
    local from="${move:0:2}"
    local to="${move:2:2}"
    local from_file=$(ord "${from:0:1}") # a-h
    local from_rank="${from:1:1}" # 1-8
    local to_file=$(ord "${to:0:1}") # a-h
    local to_rank="${to:1:1}" # 1-8

    local piece=$(get_piece "$from_file" "$from_rank")
    set_piece "$from_file" "$from_rank" "."
    set_piece "$to_file" "$to_rank" "$piece"
}

# Function to get piece from board position
get_piece() {
    local file="$1"
    local rank="$2"
    local index=$(( (8-rank)*4 + (file-1)*2 ))
    echo "${board[rank]:$index:1}"
}

# Function to set piece on board position
set_piece() {
    local file="$1"
    local rank="$2"
    local piece="$3"
    local index=$(( (8-rank)*4 + (file-1)*2 ))
    board[rank]="${board[rank]:0:$index}$piece${board[rank]:$(($index+1))}"
}

# Main script execution
main() {
    check_argument_number "$@"

    check_file_exists "$1"

    initialize_board

    parse_pgn "$1"

    current_move=0
    moves_history=()
    display_board $current_move


}

# Run the main function
main "$@"


