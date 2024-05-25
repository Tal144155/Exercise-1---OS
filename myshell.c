#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <errno.h>
#include <limits.h>

#define MAX_COMMAND_NUM 100 // max number of commands in the shell

#define MAX_COMMAND_LENGTH 100 // max length of each command

char command_history[MAX_COMMAND_NUM][MAX_COMMAND_LENGTH]; //storing all 100 commands possible

int command_counter = 0; //counter for the number of commands inside tha array at the moment


//function adding a new command to the commands history array
void add_command_to_history(char * command) {
    strcpy(command_history[command_counter], command);
    command_counter++;
}

//function printing the commands in FIFO order
void print_command_history() {
    for(int i=0;i<command_counter;i++) {
        printf("%s\n", command_history[i]);
    }
}

//function changing the directory of the shell
void change_directory(char * new_path) {
    int result_change = chdir(new_path);
    if(result_change != 0) {
        perror("cd failed");
    }
}

//function printing the current working directory
void print_working_directory() {
    char working_directory[4096];
    if (getcwd(working_directory, sizeof(working_directory)) != NULL) {
        printf("%s\n", working_directory);
    } else {
        perror("pwd failed");
    }
}

void execute_command(char * command, char * paths[], int paths_length) {  
}


void running_shell(char * paths[], int paths_length) {
    char command[MAX_COMMAND_LENGTH];
    while (1) {
        printf("$ ");
        fflush(stdout);
        if (fgets(command, sizeof(command), stdin) != NULL) {
            size_t command_length = strlen(command);
            if(command[command_length-1] = '\n') {
                command[command_length-1] = '\0';
            }
            add_command_to_history(command);
            execute_command(command, paths, paths_length);
        }
    }
}

int main(int argc, char *argv[]) {
    char * paths[argc + 1];
    int path_number = argc;

    for(int i=0;i<argc;i++) {
        paths[i] = argv[i];
    }
    running_shell(paths, path_number);
}
