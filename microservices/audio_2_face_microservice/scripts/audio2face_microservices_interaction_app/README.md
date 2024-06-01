# Using the sample a2f.py application

This application is a sample Python3 application to send audio and receive
animation data and emotion data through the A2F pipeline.

## Prerequisites

This application requires the following dependencies:
- python3
- python3-venv

You will need to provide an audio file to test out.

You will need to have a running instance of A2F controller.

### Setting up the environment

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

Then install the required dependencies:

```bash
pip3 install -r requirements.txt
```

### Running the script

Usage (`./a2f.py --help`)

```
./a2f.py <audio_file.wav> <config.yml> -u <ip>:<port>
```

The scripts takes three mandatory parameters:
 * an audio file at format PCM 16 bits
 * a yaml configuration file for the emotions parameters
 * a parameter `-u` which is the URL of the A2F Controller

E.g.:
For a local deployment with default configuration or when using the
`docker-compose` quick start, you can use `127.0.0.1:52000`.

## What does this script do?

1. Reads the audio data from a wav 16bits PCM file.
2. Reads emotions and parameters from the yaml configuration file.
3. Sends emotions, parameters and audio to the A2F Controller.
4. Receives back blendshapes, audio and emotions.
5. Saves blendshapes as animation key frames in a csv file with their name,
value and time codes.
6. Saves emotions data in multiple csv files with their values and time codes.
7. Saves the received audio as out.wav.

## Notes

The API to retrieve the emotions via metadata object is still alpha and
susceptible to changes.
