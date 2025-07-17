# Main Makefile for C Projects

# Include configuration files for definitions, output, and linking flags
include ./makefile_configs/defnfile
include ./makefile_configs/outfile

# Target to create the executable
# This rule links the object files specified in $(OBJ_FILES) to create the final executable $(TARGET).
$(TARGET): $(OBJ_FILES)
	@echo "Linking object files to create executable: $(TARGET)"
	@cc -o $(TARGET) $(OBJ_FILES) $(libs)

# Target to compile source files into object files
# This rule compiles each source file into an object file.
# The pattern rule '%.o: %.c' indicates that for each .c file, a corresponding .o file will be created.
%.o: %.c
	@echo "Compiling source file: $<"
	@cc -c $(CFLAGS) -o $@ $<

# Clean target to remove generated files
# This rule removes the executable and object files to clean the build environment.
clean:
	@echo "Cleaning up generated files..."
	@rm -f $(TARGET) $(OBJ_FILES)

# Run target to execute the program
# This rule runs the compiled executable $(TARGET).
run: $(TARGET)
	@echo "Running the program: $(TARGET)"
	@./$(TARGET)
