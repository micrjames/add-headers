#!/bin/bash

# Check if a project name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <project_name>"
    exit 1
fi

# Set the project name
PROJECT_NAME=$1

# Create the project directory at the top level
echo "Creating project directory: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME/makefile_configs"

# Copy the Makefile from the makefile_template directory to the project directory
echo "Copying Makefile to $PROJECT_NAME"
cp makefile_template/Makefile "$PROJECT_NAME/Makefile"

# Copy the defnfile from the makefile_template directory to the project directory
echo "Copying defnfile to $PROJECT_NAME/makefile_configs"
cp makefile_template/makefile_configs/defnfile "$PROJECT_NAME/makefile_configs/defnfile"

# Create the outfile with the project name
echo "Creating outfile in $PROJECT_NAME/makefile_configs"
cat <<EOL > "$PROJECT_NAME/makefile_configs/outfile"
# Output configuration for C Project

TARGET = $PROJECT_NAME
SRC_FILES = \$(TARGET).c
OBJ_FILES = \$(SRC_FILES:.c=.o)
EOL

# Create the main C source file with basic scaffolding
echo "Creating main C source file: $PROJECT_NAME.c"
cat <<EOL > "$PROJECT_NAME/$PROJECT_NAME.c"
#include <stdio.h>

int main() {
    printf("Hello, World! This is the %s project.\n", "$PROJECT_NAME");
    return 0;
}
EOL

# Print success message
echo "C project '$PROJECT_NAME' created successfully."
