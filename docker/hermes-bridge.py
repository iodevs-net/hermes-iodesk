#!/usr/bin/env python3
"""
Hermes Bridge — OpenAI-compatible API sidecar.

Runs INSIDE the hermes container, exposes /v1/chat/completions
and /v1/models on port 8642.  Uses subprocess to call the local
hermes CLI instead of Docker exec into another container.

This replaces the external iodesk-hermes-api container that required
/var/run/docker.sock access.
"""

import json
import os
import subprocess
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler

HERMES_BIN = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    ".venv", "bin", "hermes",
)

MODELS = [
    {"id": "deepseek/deepseek-v4-pro", "name": "DeepSeek V4 Pro (Frontier)",
     "object": "model", "owned_by": "deepseek"},
    {"id": "deepseek/deepseek-v4-flash", "name": "DeepSeek V4 Flash",
     "object": "model", "owned_by": "deepseek"},
    {"id": "anthropic/claude-sonnet-4.6", "name": "Claude 4.6 Sonnet",
     "object": "model", "owned_by": "anthropic"},
    {"id": "nvidia/nemotron-3-nano-30b-a3b:free", "name": "Nemotron 3 Nano (Free)",
     "object": "model", "owned_by": "nvidia"},
]

PORT = int(os.environ.get("HERMES_BRIDGE_PORT", "8642"))


class BridgeHandler(BaseHTTPRequestHandler):
    """OpenAI-compatible HTTP handler for chat completions."""

    def log_message(self, format, *args):
        sys.stderr.write(f"[BRIDGE] {args[0]} {args[1]} {args[2]}\n")

    def _send_json(self, status, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/v1/models":
            self._send_json(200, {"object": "list", "data": MODELS})
        else:
            self._send_json(404, {"error": "Not found"})

    def do_POST(self):
        if self.path != "/v1/chat/completions":
            self._send_json(404, {"error": "Not found"})
            return

        try:
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length)
            body = json.loads(raw)
        except (ValueError, json.JSONDecodeError):
            self._send_json(400, {"error": "Invalid JSON body"})
            return

        messages = body.get("messages", [])
        model = body.get("model", MODELS[3]["id"])
        query = messages[-1]["content"] if messages else ""

        print(f"[BRIDGE] query model={model} len={len(query)}", flush=True)

        try:
            result = subprocess.run(
                [HERMES_BIN, "-z", query, "-m", model, "chat", "--yolo", "-Q"],
                capture_output=True, text=True, timeout=120,
                env={**os.environ, "TERM": "dumb"},
            )
        except subprocess.TimeoutExpired:
            print("[BRIDGE] timeout", flush=True)
            self._send_json(504, {"error": "Hermes timed out (120s)"})
            return
        except FileNotFoundError:
            print(f"[BRIDGE] hermes not found at {HERMES_BIN}", flush=True)
            self._send_json(503, {"error": "Hermes CLI not available"})
            return

        response = result.stdout.strip()
        if result.returncode != 0:
            print(f"[BRIDGE] hermes error (exit={result.returncode})", flush=True)
            self._send_json(500, {"error": response or f"hermes exit {result.returncode}"})
            return

        self._send_json(200, {
            "choices": [{"message": {"role": "assistant", "content": response}}],
        })


def main():
    server = HTTPServer(("0.0.0.0", PORT), BridgeHandler)
    print(f"[BRIDGE] listening on 0.0.0.0:{PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("[BRIDGE] shutting down", flush=True)
        server.server_close()


if __name__ == "__main__":
    main()
