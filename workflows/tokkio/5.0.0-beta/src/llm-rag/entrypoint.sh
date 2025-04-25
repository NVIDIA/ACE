#!/bin/bash

# Copyright(c) 2025 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

export $(cat .env | xargs)
export CONFIG_PATH=${CONFIG_PATH:-"./configs/config.yaml"}

PORT=${PORT:-"8000"}
HOST=${HOST:-"0.0.0.0"}
APP_NAME=${APP_NAME:-"src.bot:app"}
APP_DIR=${APP_DIR:-"./"}

# Parse arguments
for arg in "$@"; do
    if [[ $arg == --config=* ]]; then
        export CONFIG_PATH="${arg#--config=}"
    elif [[ $arg == --extra-config=* ]]; then
        export EXTRA_CONFIG_PATH="${arg#--extra-config=}"
    elif [[ $arg == --port=* ]]; then
        PORT="${arg#--port=}"
    elif [[ $arg == --host=* ]]; then
        HOST="${arg#--host=}"
    elif [[ $arg == --app-name=* ]]; then
        APP_NAME="${arg#--app-name=}"
    elif [[ $arg == --app-dir=* ]]; then
        APP_DIR="${arg#--app-dir=}"
    fi
done

if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Error: Config file not found at '$CONFIG_PATH'" >&2
    exit 1
fi

if [[ -f /secrets/openai_api_key.txt ]]; then
    export OPENAI_API_KEY=$(cat /secrets/openai_api_key.txt)
fi

if [[ -f /secrets/nvidia_api_key.txt ]]; then
    export NVIDIA_API_KEY=$(cat /secrets/nvidia_api_key.txt)
fi
if [[ -f /secrets/elevenlabs_api_key.txt ]]; then
    export ELEVENLABS_API_KEY=$(cat /secrets/elevenlabs_api_key.txt)
fi


uvicorn --host $HOST --port $PORT --workers 1 $APP_NAME --reload --reload-dir $APP_DIR --reload-include $CONFIG_PATH
