#!/bin/bash

# 1. Attempt to add standard Go paths if 'go' command is missing
if ! command -v go &> /dev/null; then
    echo "Go not in PATH, checking standard locations..."
    if [ -d "/usr/local/go/bin" ]; then
        export PATH=$PATH:/usr/local/go/bin
        echo "Found Go at /usr/local/go/bin"
    elif [ -d "/opt/homebrew/bin" ]; then
        export PATH=$PATH:/opt/homebrew/bin
        echo "Found Go at /opt/homebrew/bin"
    fi
fi

# 2. Verify Go is available
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed or not found. Please install it from https://go.dev/dl/"
    exit 1
fi

echo "Using Go: $(go version)"

# 3. Locate the Backend Repo
# Assuming it is a sibling directory named 'Petwell_Backend_Repo'
BACKEND_DIR="../Petwell_Backend_Repo"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "Error: Backend directory not found at $BACKEND_DIR"
    exit 1
fi

# 4. Run the Backend
echo "Starting PetWell Backend on port 8000..."
cd "$BACKEND_DIR"
go run main.go
