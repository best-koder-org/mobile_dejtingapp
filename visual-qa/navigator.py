"""navigator.py — Layer 2: Semantic Navigation Engine

Taps UI elements by their content-desc TEXT, never by hardcoded coordinates.
Resolution-independent, works on any screen size.

Depends on Layer 1 (signatures.py) for screen detection.

Usage:
    python navigator.py
"""

import logging
import os
import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

import yaml

# ---------------------------------------------------------------------------
# Layer 1 dependency
# ---------------------------------------------------------------------------
try:
    from signatures import detect_screen  # noqa: F401 – Layer 1
except ImportError:
    def detect_screen():  # type: ignore[misc]
        raise NotImplementedError(
            "signatures.py (Layer 1) is required. "
            "Place it alongside navigator.py in visual-qa/."
        )

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
_DIR = os.path.dirname(os.path.abspath(__file__))
ACTIONS_YAML = os.path.join(_DIR, "actions.yaml")
SCREENSHOT_DIR = os.path.join(_DIR, "screenshots")

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# ADB helpers
# ---------------------------------------------------------------------------

def _run_adb(*args):
    """Run an adb command; return (stdout, stderr, returncode)."""
    cmd = ["adb"] + list(args)
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout, result.stderr, result.returncode


def dump_ui_xml():
    """Dump UIAutomator XML from the device and return the parsed root element."""
    local = os.path.join(tempfile.gettempdir(), "ui_dump.xml")
    _run_adb("shell", "uiautomator", "dump", "/sdcard/ui_dump.xml")
    _run_adb("pull", "/sdcard/ui_dump.xml", local)
    tree = ET.parse(local)
    return tree.getroot()


# ---------------------------------------------------------------------------
# Core semantic actions
# ---------------------------------------------------------------------------

def _parse_bounds(bounds_str):
    """Parse UIAutomator bounds string '[x1,y1][x2,y2]' into center (cx, cy).

    Args:
        bounds_str: e.g. '[10,20][200,80]'

    Returns:
        Tuple[int, int]: (cx, cy) center of the element.

    Raises:
        ValueError: if the string cannot be parsed.
    """
    match = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds_str)
    if not match:
        raise ValueError(f"Cannot parse bounds: {bounds_str!r}")
    x1, y1, x2, y2 = (int(match.group(i)) for i in range(1, 5))
    return (x1 + x2) // 2, (y1 + y2) // 2


def tap_by_text(target_text):
    """Tap the UI element whose ``content-desc`` or ``text`` contains *target_text*.

    Resolution-independent: computes the center from the element's ``bounds``
    attribute and issues ``adb shell input tap cx cy``.

    Args:
        target_text: Substring to search for in content-desc or text.

    Returns:
        bool: True if the element was found and tapped, False otherwise.
    """
    root = dump_ui_xml()
    for node in root.iter("node"):
        content_desc = node.get("content-desc", "")
        text = node.get("text", "")
        if target_text in content_desc or target_text in text:
            bounds = node.get("bounds", "")
            if bounds:
                cx, cy = _parse_bounds(bounds)
                _run_adb("shell", "input", "tap", str(cx), str(cy))
                logger.info("Tapped %r at (%d, %d)", target_text, cx, cy)
                return True
    logger.warning("Element %r not found in UI dump", target_text)
    return False


def type_text(value):
    """Type *value* via ``adb shell input text``.

    Spaces are replaced with ``%s`` (the adb-safe encoding).

    Args:
        value: The string to type.
    """
    safe = value.replace(" ", "%s")
    _run_adb("shell", "input", "text", safe)
    logger.info("Typed text: %r", value)


def take_screenshot(name):
    """Capture a screenshot from the device and save it locally.

    Args:
        name: Base filename (without extension) for the screenshot.

    Returns:
        str: Local path to the saved PNG file.
    """
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    remote = f"/sdcard/{name}.png"
    local = os.path.join(SCREENSHOT_DIR, f"{name}.png")
    _run_adb("shell", "screencap", "-p", remote)
    _run_adb("pull", remote, local)
    logger.info("Screenshot saved: %s", local)
    return local


# ---------------------------------------------------------------------------
# Per-screen action executor
# ---------------------------------------------------------------------------

def load_actions():
    """Load per-screen action config from ``actions.yaml``.

    Returns:
        dict: Mapping of screen name → action config.
    """
    with open(ACTIONS_YAML, "r") as fh:
        return yaml.safe_load(fh)


def advance_screen(screen_name, screen_actions):
    """Execute all configured actions for *screen_name*.

    Supported action types: ``tap``, ``skip``, ``type``, ``screenshot``.

    Args:
        screen_name: The name of the current screen.
        screen_actions: Dict loaded from ``actions.yaml``.
    """
    actions = screen_actions.get(screen_name, {}).get("actions", [])
    if not actions:
        logger.warning("No actions defined for screen: %r", screen_name)
        return

    for action in actions:
        action_type = action.get("type")
        if action_type == "tap":
            tap_by_text(action["target"])
            time.sleep(0.5)
        elif action_type == "skip":
            tap_by_text("Skip")
            time.sleep(0.5)
        elif action_type == "type":
            type_text(action["value"])
            time.sleep(0.3)
        elif action_type == "screenshot":
            take_screenshot(action["name"])
        else:
            logger.warning("Unknown action type: %r", action_type)


# ---------------------------------------------------------------------------
# State-machine navigation loop
# ---------------------------------------------------------------------------

def report_stuck(screen_name):
    """Report that automation is stuck and capture a diagnostic screenshot.

    Args:
        screen_name: The screen the loop is stuck on.
    """
    logger.error("Stuck on screen %r — retries exceeded", screen_name)
    take_screenshot(f"stuck-{screen_name}")
    sys.exit(1)


def run_navigation_loop(completed_screens=None):
    """Drive the app through its onboarding flow using a state-machine loop.

    Reacts to what the screen *currently shows* rather than following a fixed
    sequence, so it handles screen reordering automatically.

    The loop continues until a screen listed in *completed_screens* is detected
    or until it exceeds the retry limit on a single screen (calls
    :func:`report_stuck`).

    Args:
        completed_screens: Set of screen names that signal completion.
            Defaults to ``{"discover"}``.
    """
    if completed_screens is None:
        completed_screens = {"discover"}

    screen_actions = load_actions()
    previous_screen = None
    retries = 0

    while True:
        screen = detect_screen()
        current = screen.name if hasattr(screen, "name") else str(screen)

        if current in completed_screens:
            logger.info("Reached completed screen %r — navigation done", current)
            take_screenshot(f"{current}-final")
            break

        if current == previous_screen:
            retries += 1
            if retries > 3:
                report_stuck(current)
        else:
            retries = 0

        if current in screen_actions:
            advance_screen(current, screen_actions)
        else:
            logger.warning("No actions for screen %r, waiting for transition…", current)

        previous_screen = current
        time.sleep(1.0)  # wait for screen transition


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    run_navigation_loop()
