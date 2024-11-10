export PIPELINE=speech_umim
export TAG=4.1.0
export CLI_CMD="aceagent chat cli -c $PWD/$BOT_PATH --log-path ${PWD}/log"
export DOCKER_REGISTRY=nvcr.io/nvidia/ace
export DOCKER_GROUP=$(stat -c %g /var/run/docker.sock)
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)
export DOCKER_USER=$(id -u):$(id -g)
mkdir -p $PWD/speech_logs