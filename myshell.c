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

void execute_fork(char * arguments[]) {
    pid_t pid = fork();
    if (pid == 0) {
        execvp(arguments[0], arguments);
        perror("exec failed");
        exit(EXIT_FAILURE);
    } else if (pid < 0) {
        perror("fork failed");
    } else {
        wait(NULL);
    }

}

void execute_command(char * command, char * paths[], int paths_length) { 
    char * arguments[MAX_COMMAND_LENGTH];
    char * cutter = strtok(command, " ");
    int counter = 0;

    while(cutter!=NULL) {
        arguments[counter] = cutter;
        cutter = strtok(NULL, " ");
        counter++;
    }

    arguments[counter] = NULL;

    if (strcmp(arguments[0], "cd") == 0) {
        if (arguments[1] != NULL) {
            change_directory(arguments[1]);
        }
    } else if (strcmp(arguments[0], "pwd") == 0) {
        print_working_directory();
        return;
    } else if (strcmp(arguments[0], "history") == 0) {
        print_command_history();
        return;
    } else if (strcmp(arguments[0], "exit") == 0) {

        exit(0);
    }
    execute_fork(arguments);
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
    int path_length = 0;

    for(int i=1;i<argc;i++) {
        paths[i] = argv[i];
        path_length+=strlen(argv[i]) + 1; // adding 1 for the ':' to come inisde the path
    }

    //changing path with new variables, adding it to the old PATH
    char * old_path = getenv("PATH");
    size_t new_path_length = strlen(old_path) + 1 + path_length;

    char * update_path = (char *)malloc(new_path_length);

    strcpy(update_path, old_path);

    for (int i = 1; i < argc; i++) {
        strcat(update_path, ":");
        strcat(update_path, argv[i]);
    }

    setenv("PATH", update_path, 0);
    
    
    running_shell(paths, path_number);
}
