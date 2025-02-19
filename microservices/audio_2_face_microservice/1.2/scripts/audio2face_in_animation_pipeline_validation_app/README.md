# Using the sample validate.py application

Assumptions:

* Audio2Face Microservice is part of an animation pipeline.
* Audio2Face Microservice is up and running

This script is used to send an audio clip to Audio2Face Microservice.
It does not act as a server, so it cannot receive A2F's output, only send.

Services downstream from Audio2Face Microservice will receive the output of Audio2Face Microservice.

E.g.:
Audio2Face Microservice => Animation Graph Microservice => Renderer Microservice

Refer to the [ACE documentation](http://docs.nvidia.com/ace/latest/workflows/animation_pipeline/index.html) on the animation pipeline workflow for more information.

## Setup and requirements

Start by creating a python venv using

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install the the gRPC proto for python by:

- Quick installation: Install the provided `nvidia_ace` python wheel package from the
[sample_wheel/](../../proto/sample_wheel) folder.

  ```bash
  pip3 install ../../proto/sample_wheel/nvidia_ace-1.0.0-py3-none-any.whl
  ```

- Manual installation: Follow the [README](../../proto/README.md) in the
[proto/](../../proto/) folder.

Then install the requirements.txt file from this directory:

```bash
pip3 install -r requirements.txt
```

## Usage

```bash
validate.py [-h] -u URL -i ID file
```

Sample application to validate A2F setup.

```
positional arguments:
  file               PCM-16 bits mono Audio file to send to the pipeline

options:
  -h, --help         show this help message and exit
  -u URL, --url URL  URL of the Audio2Face Microservice
  -i ID, --id ID     Stream ID for the request
```
