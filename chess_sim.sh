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
    echo ""

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
        echo "$i $row  $i"
    done
    echo "  a b c d e f g h"
}

apply_move_on_board() {
    local move="$1"
    local from="${move:0:2}"
    local to="${move:2:2}"

    # checking for promotion
    local promotion_piece=""

    if [ "${#move}" -eq 5 ]; then
        promotion_piece="${move:4:1}"
    fi

    local from_file=$(from_letter_to_number "${from:0:1}") # a-h
    local from_rank="${from:1:1}" # 1-8
    local to_file=$(from_letter_to_number "${to:0:1}") # a-h
    local to_rank="${to:1:1}" # 1-8
    local piece=$(get_piece "$from_file" "$from_rank")

    if [ -n "$promotion_piece" ]; then
        if [[ "$piece" =~ [P] ]]; then
            piece=$(echo "$promotion_piece" | tr 'a-z' 'A-Z')
        else
            piece=$(echo "$promotion_piece" | tr 'A-Z' 'a-z')
        fi
    fi
    
    set_piece "$from_file" "$from_rank" "."
    set_piece "$to_file" "$to_rank" "$piece"
}

# Function to get piece from board position
get_piece() {
    local file="$1"
    local rank="$2"
    local index=$(( (file-1)*2 ))
    echo "${board[rank]:$index:1}"
}

# Function to set piece on board position
set_piece() {
    local file="$1"
    local rank="$2"
    local piece="$3"
    local index=$(( (file-1)*2 ))
    board[rank]="${board[rank]:0:$index}$piece${board[rank]:$(($index+1))}"
}

from_letter_to_number() {
    local file="$1"
    declare -A file_map=( [a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [g]=7 [h]=8 )
    echo "${file_map[$file]}"
}

game_function_loop() {
    while true; do
        echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
        read -n 1 key
        case "$key" in
            d)
                if [ $current_move -lt $move_number ]; then
                    apply_move_on_board "${uci_moves[$current_move]}"
                    ((current_move++))
                    display_board $current_move
                else
                    echo "No more moves available."
                fi
                ;;
            a)
                if [ $current_move -gt 0 ]; then
                    ((current_move--))
                    initialize_board
                    for ((i=0; i<current_move; i++)); do
                        apply_move_on_board "${uci_moves[$i]}"
                    done
                fi
                display_board $current_move
                ;;
            w)
                initialize_board
                current_move=0
                display_board $current_move
                ;;
            s)
                initialize_board
                for move in "${uci_moves[@]}"; do
                    apply_move_on_board "$move"
                done
                current_move=${#uci_moves[@]}
                display_board $current_move
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

# Main script execution
main() {
    check_argument_number "$@"

    check_file_exists "$1"

    initialize_board

    parse_pgn "$1"

    current_move=0
    display_board $current_move

    game_function_loop
}

# Run the main function
main "$@"


