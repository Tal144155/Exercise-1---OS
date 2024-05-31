#!/bin/bash


# function printing if there are wrong arguments
wrong_input() {
    if [ $# -ne 2 ]; then
        echo "Usage: $0 <source_pgn_file> <destination_directory>"
        exit 1
    fi
}

# function to check if the directory exists
directory_existing_valid() {
    if [ ! -d $1 ]; then
        mkdir -p "$1"
        echo "Created directory '$1'."
    fi
}

# function to check if the file exists
file_existing_valid() {
    if [ ! -f $1 ]; then
        echo "Error: File '$1' does not exist."
        exit 1
    fi
}

#function to split the PGN file
split_pgn_file() {
    # creating local variables to hold the data needed
    local file=$1
    local directory=$2
    local counter_games=0
    local new_pgn_file
    local file_name=$(basename "$file" .pgn)

    while IFS= read -r line; do
        if [[ "$line" =~ ^\[Event\  ]]; then
            ((counter_games++))
            new_pgn_file="${directory}/${file_name}_${counter_games}.pgn"
            echo "Saved game to $new_pgn_file"
            touch "$new_pgn_file"
            echo "$line" >> "$new_pgn_file"
        else
            echo "$line" >> "$new_pgn_file"
        fi
    done < "$file"
    echo "All games have been split and saved to '$directory'."
}


file=$1
directory=$2

wrong_input "$@"

file_existing_valid "$file"

directory_existing_valid "$directory"

split_pgn_file "$file" "$directory"



