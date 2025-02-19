#!/bin/bash

# Input directory containing .proto files, default to ./proto/ if not provided
INPUT_DIR=${1:-"./../../proto/"}
# Output directory, default to current directory if not provided
OUTPUT_DIR=${2:-"./"}

# Check if protoc is installed
if ! command -v python3 -m grpc_tools.protoc &> /dev/null
then
  echo "Error: protoc is not installed. Please install it first."
  exit 1
fi

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: Directory $INPUT_DIR not found."
  exit 1
fi

# Compile .proto file(s) in the input directory
echo "Compiling .proto files in $INPUT_DIR..."
python3 -m grpc_tools.protoc --proto_path=${INPUT_DIR} --python_out=${OUTPUT_DIR} --grpc_python_out=${OUTPUT_DIR} ${INPUT_DIR}*.proto
if [ $? -ne 0 ]; then
  echo "Failed to compile .proto files in $INPUT_DIR."
  exit 1
fi

echo "Compilation complete. Python files are located in ${OUTPUT_DIR}"