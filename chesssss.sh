#!/bin/bash

# Function to display the board
display_board() {
    clear
    echo "Move $1/${#moves_history[@]}"
    echo "  a b c d e f g h"
    for ((i=8; i>=1; i--)); do
        row="${board[i]}"
        echo "$i $row $i"
    done
    echo "  a b c d e f g h"
    echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
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

# Function to parse PGN file and display metadata
parse_pgn() {
    if [ ! -f "$1" ]; then
        echo "File does not exist: $1"
        exit 1
    fi

    metadata=$(grep -E '^\[.*\]$' "$1")
    moves=$(grep -v '^\[.*\]$' "$1" | tr -d '\n' | sed 's/[0-9]\+\.\s*//g')

    echo "Metadata from PGN file:"
    echo "$metadata"

    python3 parse_moves.py "$moves" > moves.txt
    uci_moves=($(cat moves.txt))
    rm moves.txt
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

    local piece=$(get_pit, vjueho? tbjbu f,cbuece "$from_file" "$from_rank")
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

# Function to convert file character to number
ord() {
    printf "%d" "'$1"
}

# Function to handle user input
handle_input() {
    while true; do
        read -n 1 key
        case "$key" in
            d)
                if [ $current_move -lt ${#uci_moves[@]} ]; then
                    apply_uci_move "${uci_moves[$current_move]}"
                    ((current_move++))
                    moves_history+=("${uci_moves[$current_move-1]}")
                else
                    echo "No more moves available."
                fi
                ;;
            a)
                if [ $current_move -gt 0 ]; then
                    ((current_move--))
                    initialize_board
                    for ((i=0; i<current_move; i++)); do
                        apply_uci_move "${uci_moves[$i]}"
                    done
                    moves_history=("${uci_moves[@]:0:$current_move}")
                fi
                ;;
            w)
                initialize_board
                current_move=0
                moves_history=()
                ;;
            s)
                initialize_board
                for move in "${uci_moves[@]}"; do
                    apply_uci_move "$move"
                done
                current_move=${#uci_moves[@]}
                moves_history=("${uci_moves[@]}")
                ;;
            q)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo "Invalid key pressed: $key"
                ;;
        esac
        display_board $current_move
    done
}

# Main script execution
main() {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <pgn_file>"
        exit 1
    fi

    initialize_board
    parse_pgn "$1"

    current_move=0
    moves_history=()
    display_board $current_move

    handle_input
}

# Run the main function
main "$@"
