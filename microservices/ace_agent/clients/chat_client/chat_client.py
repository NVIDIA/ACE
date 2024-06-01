"""
 copyright(c) 2022-24 NVIDIA Corporation.All rights reserved.

 NVIDIA Corporation and its licensors retain all intellectual property
 and proprietary rights in and to this software, related documentation
 and any modifications thereto.Any use, reproduction, disclosure or
 distribution of this software and related documentation without an express
 license agreement from NVIDIA Corporation is strictly prohibited.
"""

"""
This sample python application showcases how any developer can communicate with the REST-based API's exposed by the Chat Engine.
"""

import json
import argparse
import uuid
import aiohttp
import asyncio

parser = argparse.ArgumentParser(description="Application to demonstrate interactions with Agent Server")
parser.add_argument("--host", default="localhost", help="hostname to be used by the server")
parser.add_argument("--port", default=9000, help="port to be used by the server")
parser.add_argument("--timeout", default=15, help="Maximum time to wait for response")

args = parser.parse_args()

user_id = str(uuid.uuid4())


async def check_status():
    """
    Send a request to the isReady endpoint at the specified host and port.
    Input: None
    Output: True if server is active, else False
    """

    # Check if server is active and ready to process queries
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(args.timeout)) as session:
            async with session.get(f"http://{args.host}:{args.port}/isReady") as resp:
                if resp.ok:
                    print("Server is active and ready to process queries!")
                else:
                    print("Server is not ready to process queries. Please ensure that server is running.")
                    return False
    except:
        print("Could not reach server. Exiting.")
        return False

    return True


async def chat():
    """
    Call the /chat endpoint of Chat Engine and handle the response (whether streaming or non-streaming).
    """
    query = input("[YOU] ").strip()
    if not query:
        return

    payload = {"UserId": user_id, "Query": query}

    # Post a request to ACE Agent server hosted at args.host:args.port.
    # The payload is a dict containing information relavent to ACE Agent.
    # The fields in the current payload are mandatory, but some other information can also be passed.
    # Refer to Nvidia ACE Agent documentation to find out the valid data fields you can send.
    try:
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(args.timeout)) as session:
            async with session.post(f"http://{args.host}:{args.port}/chat", json=payload) as response:
                response.raise_for_status()

                # In case of a streaming response, print each chunk as it is received
                if response.headers.get("Transfer-Encoding") == "chunked":
                    print("[BOT] ", end="", flush=True)
                    async for chunk, _ in response.content.iter_chunks():
                        if not chunk:
                            break

                        chunk = chunk.decode("utf-8")
                        parsed_chunk = json.loads(chunk)
                        if parsed_chunk["Response"]["IsFinal"]:
                            print("")
                            return
                        else:
                            print(parsed_chunk["Response"]["Text"], end="", flush=True)

                # In case of a JSON response, return the value directly
                else:
                    response_data = await response.json()
                    print(f"[BOT] {response_data['Response']['CleanedText']}")

    except KeyboardInterrupt:
        print("Force interrupting Chat Engine Sample App")
        return

    except Exception as e:
        return f"Ran into an error while querying the bot: {e}"


async def main():
    """
    Run the Chat Engine sample app functionality.
    Output: None
    """

    server_up = await check_status()
    if not server_up:
        exit()

    while True:
        try:
            await chat()
        except KeyboardInterrupt:
            return


if __name__ == "__main__":
    asyncio.run(main())
