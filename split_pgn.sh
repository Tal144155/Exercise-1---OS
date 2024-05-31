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
    local file=$1                    # store the source PGN file path
    local directory=$2               # store the destination directory path
    local counter_games=0            # initialize the game counter
    local new_pgn_file               # variable to hold the new PGN file path
    local file_name=$(basename "$file" .pgn)  # extract the file name from the source PGN file path

    # loop through each line in the PGN file
    while IFS= read -r line; do
        # check if the line starts with '[Event  '
        if [[ "$line" =~ ^\[Event\  ]]; then

            # increment the game counter
            ((counter_games++))

            # create a new PGN file name
            new_pgn_file="${directory}/${file_name}_${counter_games}.pgn"

            # print a message indicating the new file name
            echo "Saved game to $new_pgn_file"

            # create the new PGN file
            touch "$new_pgn_file"

            # write the current line to the new PGN file
            echo "$line" >> "$new_pgn_file"
        else
            # write the current line to the current PGN file
            echo "$line" >> "$new_pgn_file"
        fi
    done < "$file"

    # print a message indicating that all games have been split and saved
    echo "All games have been split and saved to '$directory'."
}


file=$1
directory=$2

wrong_input "$@"

file_existing_valid "$file"

directory_existing_valid "$directory"

split_pgn_file "$file" "$directory"



