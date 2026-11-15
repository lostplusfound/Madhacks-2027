"""Call a local stdio MCP bridge when it is not exposed as a session tool."""

import argparse
import asyncio
import json
import os
import signal
from pathlib import Path


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("tool")
    parser.add_argument("--arguments", default="{}")
    parser.add_argument("--dart", action="store_true")
    parser.add_argument("--dtd", help="Connect to DTD before invoking the Dart tool")
    args = parser.parse_args()
    server = Path(__file__).resolve().parents[3] / "madmaps_server"
    command = (
        ["dart", "mcp-server", "--force-roots-fallback"]
        if args.dart
        else ["serverpod", "mcp-server", "--server-dir", str(server)]
    )
    process = await asyncio.create_subprocess_exec(
        *command,
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
        start_new_session=True,
    )

    async def send(message):
        process.stdin.write((json.dumps(message) + "\n").encode())
        await process.stdin.drain()

    async def receive(request_id):
        while True:
            line = await asyncio.wait_for(process.stdout.readline(), timeout=180)
            if not line:
                raise RuntimeError("MCP bridge closed unexpectedly")
            try:
                response = json.loads(line)
            except ValueError:
                continue
            if "method" in response and "id" in response:
                if response["method"] == "roots/list":
                    await send(
                        {
                            "jsonrpc": "2.0",
                            "id": response["id"],
                            "result": {
                                "roots": [
                                    {"uri": server.parent.as_uri(), "name": "MadMaps"}
                                ]
                            },
                        }
                    )
                else:
                    await send(
                        {
                            "jsonrpc": "2.0",
                            "id": response["id"],
                            "error": {
                                "code": -32601,
                                "message": "Unsupported client method",
                            },
                        }
                    )
            if "method" not in response and response.get("id") == request_id:
                return response

    try:
        await send(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"roots": {"listChanged": False}},
                    "clientInfo": {"name": "madmaps-local-check", "version": "1"},
                },
            }
        )
        await receive(1)
        await send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        if args.dtd:
            await send(
                {
                    "jsonrpc": "2.0",
                    "id": 3,
                    "method": "tools/call",
                    "params": {
                        "name": "dtd",
                        "arguments": {"command": "connect", "uri": args.dtd},
                    },
                }
            )
            connection = await receive(3)
            if connection.get("result", {}).get("isError"):
                print(json.dumps(connection), flush=True)
                return
        method = "tools/list" if args.tool == "list" else "tools/call"
        message = {"jsonrpc": "2.0", "id": 2, "method": method}
        if method == "tools/call":
            message["params"] = {
                "name": args.tool,
                "arguments": json.loads(args.arguments),
            }
        await send(message)
        print(json.dumps(await receive(2), indent=2), flush=True)
    finally:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            await asyncio.wait_for(process.wait(), timeout=5)
        except TimeoutError:
            os.killpg(process.pid, signal.SIGKILL)
            await process.wait()


if __name__ == "__main__":
    asyncio.run(main())
