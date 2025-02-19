# Prerequisite

Make sure:

* [Docker](https://docs.docker.com/get-docker/)
* [NVIDIA container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
* [Docker Compose](https://docs.docker.com/compose/install/)

are installed on your machine.

# Getting started

To run the containers on your machine you need to run docker compose in the same directory as the  `docker-compose.yml` file:

```
$ docker compose up
```

The first run will take several minutes as both Audio2Emotion and Audio2Face TRT model have to be generated.
For the subsequent starts, this step will be cached.

You can Ctrl+C to interrupt this deployment.

You will see some logs containing `Running...` in stdout when Audio2Face is up and running.

# Configuration files

The provided configuration file will be used by Audio2Face and A2F Controller at Startup.
If you update them, you will need to interrupt and run again the containers.
(Ctrl+C and then `$ docker compose up`)

# Troubleshooting

If your deployment is in an invalid state, or encounters errors while starting, you can clean up local running dockers.

To remove the cached Audio2Emotion and Audio2Face models:
```
$ docker compose down -v
```

To remove all current docker containers:
```
$ docker container prune -f 
```
