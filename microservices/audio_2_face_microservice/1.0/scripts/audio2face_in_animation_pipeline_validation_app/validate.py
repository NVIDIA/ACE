#!/usr/bin/env python3

# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import asyncio
import uuid

import scipy
from nvidia_ace.animation_id.v1_pb2 import AnimationIds
from nvidia_ace.audio.v1_pb2 import AudioHeader
import numpy as np
from nvidia_ace.services.a2f.v1_pb2_grpc import A2FServiceStub
from nvidia_ace.a2f.v1_pb2 import AudioStream, AudioStreamHeader, AudioWithEmotion
import grpc


# Sends an audio clip with the specified stream_id
# This stream_id allows to send multiple audio clips to the same avatar
async def write(stream, sample_rate: int, audio_data, stream_id):
    # Sends the audio stream header with audio metadata and ids
    # Refer to the proto files for more information
    await stream.write(
        AudioStream(
            audio_stream_header=AudioStreamHeader(
                audio_header=AudioHeader(
                    channel_count=1,
                    samples_per_second=sample_rate,
                    bits_per_sample=16,
                    audio_format=AudioHeader.AudioFormat.AUDIO_FORMAT_PCM,
                ),
                animation_ids=AnimationIds(
                    request_id=str(uuid.uuid4()),
                    target_object_id=str(uuid.uuid4()),
                    stream_id=stream_id,
                ),
            ),
        )
    )

    # Iterate over the audio data to send audio chunks
    for i in range(len(audio_data) // sample_rate + 1):
        # Create an audio chunk
        chunk = audio_data[i * sample_rate: i * sample_rate + sample_rate]
        # Send an audio chunk
        await stream.write(
            AudioStream(
                audio_with_emotion=AudioWithEmotion(
                    audio_buffer=chunk.astype(np.int16).tobytes(),
                    emotions=[],
                )
            )
        )
    # close the sending process
    await stream.done_writing()


parser = argparse.ArgumentParser(
    description="Sample application to validate A2F setup.",
    epilog="NVIDIA CORPORATION.  All rights reserved.",
)

parser.add_argument("file", help="PCM-16 bits mono Audio file to send to the pipeline")
parser.add_argument("-u", "--url", help="URL of the Audio2Face Microservice", required=True)
parser.add_argument("-i", "--id", help="Stream ID for the request", required=True)


async def main():
    args = parser.parse_args()

    # extract sample rate and audio data from the provided audio file
    sample_rate, data = scipy.io.wavfile.read(args.file)

    # create a gRPC channel
    async with grpc.aio.insecure_channel(args.url) as channel:
        # create gRPC stub and stream
        stub = A2FServiceStub(channel)
        stream = stub.PushAudioStream()
        # Send the audio clip
        await write(stream, sample_rate, data, args.id)
        print(await stream)


if __name__ == "__main__":
    asyncio.run(main())
