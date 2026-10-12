#!/usr/bin/env python3
"""WebDriverAgent-based simulator driver for persona flow sims.

Drives an iOS simulator through the WDA HTTP bridge (localhost:8100) so flows
can be automated without SimulatorKit/HID support, which is unavailable on
trimmed Xcode installs.

Usage:
  python3 tools/sim_drive.py tap 198 520
  python3 tools/sim_drive.py swipe 200 600 200 200
  python3 tools/sim_drive.py source out.xml
  python3 tools/sim_drive.py type "hello"

Coordinates are in simulator points (screen-space of the device, e.g. 393x852
for iPhone 16). Screenshots keep using `xcrun simctl io <udid> screenshot`.

Setup (one-time per sim session):
  xcodebuild test-without-building \
    -xctestrun <WDA products>/*.xctestrun \
    -destination 'platform=iOS Simulator,id=<UDID>' &
Requires WDA built once via `xcodebuild build-for-testing -scheme WebDriverAgentRunner`.
"""

import argparse
import base64
import json
import sys
import urllib.request

WDA = "http://127.0.0.1:8100"
_session = None


def _post(path, payload):
    req = urllib.request.Request(
        WDA + path,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        body = json.loads(r.read().decode())
    if body.get("status", 0) != 0:
        raise RuntimeError(f"WDA error on {path}: {body}")
    return body.get("sessionId", _session)


def _get(path):
    with urllib.request.urlopen(WDA + path, timeout=30) as r:
        return r.read()


def session():
    global _session
    if _session is None:
        _session = _post(
            "/session",
            {"capabilities": {"alwaysMatch": {"platformName": "iOS"}}},
        )
    return _session


def tap(x, y):
    """W3C pointer actions tap: coordinates are in screen points."""
    _post(
        f"/session/{session()}/actions",
        {
            "actions": [
                {
                    "type": "pointer",
                    "id": "finger1",
                    "parameters": {"pointerType": "touch"},
                    "actions": [
                        {"type": "pointerMove", "duration": 0, "x": x, "y": y},
                        {"type": "pointerDown", "button": 0},
                        {"type": "pause", "duration": 80},
                        {"type": "pointerUp", "button": 0},
                    ],
                }
            ]
        },
    )


def swipe(x1, y1, x2, y2, duration_ms=400):
    _post(
        f"/session/{session()}/actions",
        {
            "actions": [
                {
                    "type": "pointer",
                    "id": "finger1",
                    "parameters": {"pointerType": "touch"},
                    "actions": [
                        {"type": "pointerMove", "duration": 0, "x": x1, "y": y1},
                        {"type": "pointerDown", "button": 0},
                        {"type": "pointerMove", "duration": duration_ms, "x": x2, "y": y2},
                        {"type": "pointerUp", "button": 0},
                    ],
                }
            ]
        },
    )


def type_text(text):
    _post(
        f"/session/{session()}/wda/keys",
        {"value": list(text)},
    )


def source(out_path=None):
    xml = _get(f"/session/{session()}/source")
    if out_path:
        with open(out_path, "wb") as f:
            f.write(xml)
        print(f"wrote {out_path} ({len(xml)} bytes)")
    else:
        sys.stdout.write(xml.decode(errors="replace"))


def screenshot_b64(out_path):
    data = _get(f"/session/{session()}/screenshot")
    payload = json.loads(data.decode())["value"]
    with open(out_path, "wb") as f:
        f.write(base64.b64decode(payload))
    print(f"wrote {out_path}")


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("tap")
    t.add_argument("x", type=float)
    t.add_argument("y", type=float)
    s = sub.add_parser("swipe")
    s.add_argument("x1", type=float)
    s.add_argument("y1", type=float)
    s.add_argument("x2", type=float)
    s.add_argument("y2", type=float)
    s.add_argument("--ms", type=int, default=400)
    k = sub.add_parser("type")
    k.add_argument("text")
    src = sub.add_parser("source")
    src.add_argument("out", nargs="?")
    shot = sub.add_parser("shot")
    shot.add_argument("out")
    args = p.parse_args()
    if args.cmd == "tap":
        tap(args.x, args.y)
        print(f"tapped {args.x},{args.y}")
    elif args.cmd == "swipe":
        swipe(args.x1, args.y1, args.x2, args.y2, args.ms)
        print(f"swiped {args.x1},{args.y1} -> {args.x2},{args.y2}")
    elif args.cmd == "type":
        type_text(args.text)
        print(f"typed {args.text!r}")
    elif args.cmd == "source":
        source(args.out)
    elif args.cmd == "shot":
        screenshot_b64(args.out)


if __name__ == "__main__":
    main()
