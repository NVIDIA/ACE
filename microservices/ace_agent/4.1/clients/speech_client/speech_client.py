# SPDX-FileCopyrightText: Copyright (c) 2022-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

# First we will import all the necessary dependencies
import argparse
import wave
import os
import grpc
import time
import uuid
import json

# We need to import python lib files generated from the proto
import ace_agent_pb2
import ace_agent_pb2_grpc


if __name__ == "__main__":
    # Parse arguments
    help_msg = "Speech Client App"
    parser = argparse.ArgumentParser(description=help_msg)
    parser.add_argument("--audio_file_path", type=str, help="ASR input audio wav file path")
    parser.add_argument("--tts_output_path", default="tts_output.wav", type=str, help="TTS output audio wav file path")
    parser.add_argument("--server", default="0.0.0.0:50055", type=str, help="GRPC Server URL")
    args = parser.parse_args()

    # First lets validate the audio file path received in args
    input_audio_file_path = args.audio_file_path
    if not input_audio_file_path or not os.path.exists(input_audio_file_path):
        print("ASR audio input file path is not valid")
        exit(0)

    # We will now create a grpc client stub using the Chat Controller Grpc server address
    channel = grpc.insecure_channel(args.server)
    stub = ace_agent_pb2_grpc.AceAgentGrpcStub(channel)

    # After creating the stub, we will now try to acquire a pipeline on Chat Controller server
    # We need to send a unique streamID in the request,  we will use stream-1 for now
    streamId = str(uuid.uuid4())
    print(f"Using streamId {streamId}")
    pipeline_request = ace_agent_pb2.PipelineRequest(stream_id=streamId)
    status_response = stub.CreatePipeline(pipeline_request)
    time.sleep(5)
    # If we get a status = PIPELINE_AVAILABLE, it means the pipeline has been allocated successfully else we exit
    if status_response.status == ace_agent_pb2.PIPELINE_AVAILABLE:
        print("Pipeline created successfully...")
    else:
        print(f"Could not create pipeline due, status response: {status_response}")

    # Now we will read audio data from a wav file and send audio query to Chat Controller server
    with wave.open(input_audio_file_path, "rb") as audio_file:
        # We need to read audio data in chunks of frames, lets read the data in chunks of 1600 frames
        def generator(audio_file):
            CHUNK = 1600
            sample_rate = audio_file.getframerate()
            channels = audio_file.getnchannels()
            frame_size = audio_file.getsampwidth()
            audio_content = None
            config = ace_agent_pb2.StreamingRecognitionConfig(
                encoding=ace_agent_pb2.LINEAR_PCM, sample_rate_hertz=sample_rate, audio_channel_count=channels
            )

            yield ace_agent_pb2.SendAudioRequest(streaming_config=config, stream_id=streamId)

            while True:
                audio_content = audio_file.readframes(CHUNK)

                if len(audio_content) <= 0:
                    break
                else:
                    yield ace_agent_pb2.SendAudioRequest(audio_content=audio_content)

                # We add a delay to the audio streaming to simulate a real time audio streaming
                bytes_read = len(audio_content)
                if bytes_read > 0:
                    time.sleep(0.05)

            # Simulate a silence of 1 second at the end of the audio to indicate end of speech
            # We'll split the silence into 10 chunks for easier processing
            number_of_chunks = 10
            silence_duration = 1
            for _ in range(number_of_chunks):
                empty_buffers = bytes((sample_rate * frame_size * silence_duration) // number_of_chunks)
                time.sleep(len(empty_buffers) / (sample_rate * frame_size))
                yield ace_agent_pb2.SendAudioRequest(audio_content=empty_buffers, stream_id=streamId)

        request_status = stub.SendAudio(generator(audio_file))
        print(request_status)

    # Now we will receive the TTS audio data back from Chat Controller server and write it to a wav file
    output_audio_file_path = args.tts_output_path
    receive_audio_request = ace_agent_pb2.ReceiveAudioRequest(stream_id=streamId)

    first_chunk = True
    config_set = False

    try:
        with wave.open(output_audio_file_path, "w") as output_audio_file:
            responses = stub.ReceiveAudio(receive_audio_request, timeout=10)
            for response in responses:
                # Here we check if this is the first chunk of the incoming audio data,
                # if yes, then we use this chunk to get the information about the audio buffer
                # in order to configure the wav writer
                if first_chunk:
                    output_audio_file.setnchannels(response.audio_channel_count)
                    output_audio_file.setsampwidth(response.frame_size)
                    output_audio_file.setframerate(response.sample_rate_hertz)
                    first_chunk = False
                    config_set = True
                if config_set:
                    data = response.audio_content
                    output_audio_file.writeframesraw(data)

            output_audio_file.close()
    except Exception as e:
        print(f"Exception occurred in getting TTS data")

    # Now we will call the Server side streaming Stream Speech Results API for streaming all the metadata from Chat Controller
    # We need to send a unique request_id as well along with the stream_id in this request header.

    stream_speech_results_request = ace_agent_pb2.StreamingSpeechResultsRequest(
        stream_id=streamId, request_id=str(uuid.uuid4())
    )
    streaming_responses = stub.StreamSpeechResults(stream_speech_results_request, timeout=10)

    # All new responses received on the grpc stream will now be printed in this loop.
    # The messages contain ASR transcripts, Chat Engine Response, Pipeline states and TTS latency etc.
    print("ASR Transcripts:")
    try:
        for response in streaming_responses:
            if response.message_type == ace_agent_pb2.ASR_RESPONSE:
                if not response.asr_result.results.is_final:
                    print(f"[PARTIAL] : {response.asr_result.results.alternatives[0].transcript}")
                else:
                    print(f"[FINAL] : {response.asr_result.results.alternatives[0].transcript}")
            elif response.message_type == ace_agent_pb2.CHAT_ENGINE_RESPONSE:
                chat_engine_response = json.loads(response.chat_engine_response.result)["Response"]["Text"]
                print(f"Bot Response: {chat_engine_response}")
            # The TTS response is the final response we are expecting after ASR and Chat Engine response.
            # Hence we will break the loop here
            elif response.message_type == ace_agent_pb2.TTS_RESPONSE:
                break
    except Exception as e:
        print(f"Response loop terminated due to an exception")
# Once done with all the requests, We will now free up the acquired pipeline on the Chat Controller server
pipeline_request = ace_agent_pb2.PipelineRequest(stream_id=streamId)
status_response = stub.FreePipeline(pipeline_request)
# If we get a status_response.response_msg saying Pipeline is released, it means the pipeline has been released successfully
print(status_response)
