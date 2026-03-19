"""test_navigator.py — Unit tests for navigator.py (Layer 2)

All adb calls are patched so no real device is required.
"""

import os
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import MagicMock, call, patch

# ---------------------------------------------------------------------------
# Bootstrap: add visual-qa/ to the path and stub out the Layer 1 dependency
# before importing navigator.
# ---------------------------------------------------------------------------
_VISUAL_QA_DIR = os.path.join(os.path.dirname(__file__), "..")
sys.path.insert(0, _VISUAL_QA_DIR)

# Provide a minimal stub for signatures.py (Layer 1) so navigator can import.
_signatures_stub = MagicMock()
sys.modules.setdefault("signatures", _signatures_stub)

import navigator  # noqa: E402  (import after path/stub setup)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

SAMPLE_XML = textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <hierarchy rotation="0">
      <node text="" content-desc="Man" bounds="[10,10][110,60]" />
      <node text="Next" content-desc="" bounds="[50,500][300,554]" />
      <node text="Skip" content-desc="Skip" bounds="[200,20][280,50]" />
      <node text="" content-desc="Skip Photos" bounds="[0,600][320,654]" />
    </hierarchy>
""")


def _make_adb_side_effect(xml_content=SAMPLE_XML):
    """Return a subprocess.run side-effect that writes *xml_content* on pull."""
    _tmp = os.path.join(tempfile.gettempdir(), "ui_dump.xml")

    def _fake_run(cmd, **kwargs):
        result = MagicMock()
        result.returncode = 0
        result.stdout = ""
        result.stderr = ""
        if "pull" in cmd:
            with open(_tmp, "w") as fh:
                fh.write(xml_content)
        return result

    return _fake_run


# ---------------------------------------------------------------------------
# _parse_bounds
# ---------------------------------------------------------------------------

class TestParseBounds(unittest.TestCase):
    def test_origin_zero(self):
        cx, cy = navigator._parse_bounds("[0,0][100,200]")
        self.assertEqual(cx, 50)
        self.assertEqual(cy, 100)

    def test_non_zero_origin(self):
        cx, cy = navigator._parse_bounds("[200,300][600,700]")
        self.assertEqual(cx, 400)
        self.assertEqual(cy, 500)

    def test_element_from_sample_xml_man(self):
        # bounds="[10,10][110,60]" → cx=60, cy=35
        cx, cy = navigator._parse_bounds("[10,10][110,60]")
        self.assertEqual(cx, 60)
        self.assertEqual(cy, 35)

    def test_invalid_string_raises(self):
        with self.assertRaises(ValueError):
            navigator._parse_bounds("not-bounds")

    def test_empty_string_raises(self):
        with self.assertRaises(ValueError):
            navigator._parse_bounds("")


# ---------------------------------------------------------------------------
# tap_by_text
# ---------------------------------------------------------------------------

class TestTapByText(unittest.TestCase):
    @patch("navigator.subprocess.run")
    def test_tap_by_content_desc(self, mock_run):
        mock_run.side_effect = _make_adb_side_effect()
        result = navigator.tap_by_text("Man")
        self.assertTrue(result)
        # bounds=[10,10][110,60] → cx=60, cy=35
        tap_calls = [c for c in mock_run.call_args_list if "tap" in str(c)]
        self.assertTrue(
            any("60" in str(c) and "35" in str(c) for c in tap_calls),
            f"Expected tap at (60,35) in calls: {tap_calls}",
        )

    @patch("navigator.subprocess.run")
    def test_tap_by_text_attribute(self, mock_run):
        mock_run.side_effect = _make_adb_side_effect()
        result = navigator.tap_by_text("Next")
        self.assertTrue(result)

    @patch("navigator.subprocess.run")
    def test_tap_returns_false_when_not_found(self, mock_run):
        mock_run.side_effect = _make_adb_side_effect()
        result = navigator.tap_by_text("NonExistentButton")
        self.assertFalse(result)

    @patch("navigator.subprocess.run")
    def test_tap_partial_match_in_content_desc(self, mock_run):
        mock_run.side_effect = _make_adb_side_effect()
        # "Skip" is a substring of "Skip Photos"
        result = navigator.tap_by_text("Skip Photos")
        self.assertTrue(result)

    @patch("navigator.subprocess.run")
    def test_tap_skip_matches_content_desc(self, mock_run):
        mock_run.side_effect = _make_adb_side_effect()
        result = navigator.tap_by_text("Skip")
        self.assertTrue(result)


# ---------------------------------------------------------------------------
# type_text
# ---------------------------------------------------------------------------

class TestTypeText(unittest.TestCase):
    @patch("navigator._run_adb")
    def test_spaces_encoded(self, mock_adb):
        navigator.type_text("hello world")
        mock_adb.assert_called_once_with("shell", "input", "text", "hello%sworld")

    @patch("navigator._run_adb")
    def test_no_spaces(self, mock_adb):
        navigator.type_text("TestUser")
        mock_adb.assert_called_once_with("shell", "input", "text", "TestUser")

    @patch("navigator._run_adb")
    def test_multiple_spaces(self, mock_adb):
        navigator.type_text("a b c")
        mock_adb.assert_called_once_with("shell", "input", "text", "a%sb%sc")


# ---------------------------------------------------------------------------
# take_screenshot
# ---------------------------------------------------------------------------

class TestTakeScreenshot(unittest.TestCase):
    @patch("navigator._run_adb")
    @patch("navigator.os.makedirs")
    def test_creates_dir_and_calls_adb(self, mock_makedirs, mock_adb):
        path = navigator.take_screenshot("discover-empty")
        mock_makedirs.assert_called_once_with(navigator.SCREENSHOT_DIR, exist_ok=True)
        # screencap + pull
        calls = mock_adb.call_args_list
        self.assertTrue(any("screencap" in str(c) for c in calls))
        self.assertTrue(any("pull" in str(c) for c in calls))
        self.assertTrue(path.endswith("discover-empty.png"))


# ---------------------------------------------------------------------------
# advance_screen
# ---------------------------------------------------------------------------

_SCREEN_ACTIONS = {
    "gender": {
        "actions": [
            {"type": "tap", "target": "Man"},
            {"type": "tap", "target": "Next"},
        ]
    },
    "orientation": {
        "actions": [{"type": "skip"}]
    },
    "photos": {
        "actions": [{"type": "tap", "target": "Skip Photos"}]
    },
    "first_name": {
        "actions": [
            {"type": "type", "value": "TestUser"},
            {"type": "tap", "target": "Next"},
        ]
    },
    "discover": {
        "actions": [
            {"type": "screenshot", "name": "discover-main"},
            {"type": "tap", "target": "Discovery Filters"},
        ]
    },
    "discover_explore": {
        "actions": [
            {"type": "screenshot", "name": "discover-filter-open"},
            {"type": "tap", "target": "Done"},
        ]
    },
}


class TestAdvanceScreen(unittest.TestCase):
    @patch("navigator.time.sleep")
    @patch("navigator.take_screenshot")
    @patch("navigator.tap_by_text", return_value=True)
    def test_gender_taps_man_then_next(self, mock_tap, mock_screenshot, mock_sleep):
        navigator.advance_screen("gender", _SCREEN_ACTIONS)
        mock_tap.assert_any_call("Man")
        mock_tap.assert_any_call("Next")
        self.assertEqual(mock_tap.call_count, 2)

    @patch("navigator.time.sleep")
    @patch("navigator.take_screenshot")
    @patch("navigator.tap_by_text", return_value=True)
    def test_skip_action_taps_skip(self, mock_tap, mock_screenshot, mock_sleep):
        navigator.advance_screen("orientation", _SCREEN_ACTIONS)
        mock_tap.assert_called_once_with("Skip")

    @patch("navigator.time.sleep")
    @patch("navigator.take_screenshot")
    @patch("navigator.tap_by_text", return_value=True)
    def test_screenshot_action(self, mock_tap, mock_screenshot, mock_sleep):
        navigator.advance_screen("discover", _SCREEN_ACTIONS)
        mock_screenshot.assert_called_once_with("discover-main")
        mock_tap.assert_called_once_with("Discovery Filters")

    @patch("navigator.time.sleep")
    @patch("navigator._run_adb")
    @patch("navigator.tap_by_text", return_value=True)
    def test_type_action(self, mock_tap, mock_adb, mock_sleep):
        navigator.advance_screen("first_name", _SCREEN_ACTIONS)
        mock_adb.assert_called_with("shell", "input", "text", "TestUser")

    @patch("navigator.tap_by_text", return_value=True)
    def test_no_actions_for_unknown_screen(self, mock_tap):
        navigator.advance_screen("unknown_screen", _SCREEN_ACTIONS)
        mock_tap.assert_not_called()


# ---------------------------------------------------------------------------
# State-machine loop
# ---------------------------------------------------------------------------

class TestRunNavigationLoop(unittest.TestCase):
    def _make_screen(self, name):
        s = MagicMock()
        s.name = name
        return s

    @patch("navigator.time.sleep")
    @patch("navigator.take_screenshot")
    @patch("navigator.advance_screen")
    @patch("navigator.load_actions", return_value=_SCREEN_ACTIONS)
    @patch("navigator.detect_screen")
    def test_runs_terminal_screen_actions_before_exit(
        self, mock_detect, mock_load, mock_advance, mock_screenshot, mock_sleep
    ):
        mock_detect.return_value = self._make_screen("discover")
        navigator.run_navigation_loop(completed_screens={"discover"})
        mock_advance.assert_called_once_with("discover", _SCREEN_ACTIONS)

    @patch("navigator.time.sleep")
    @patch("navigator.take_screenshot")
    @patch("navigator.advance_screen")
    @patch("navigator.load_actions", return_value=_SCREEN_ACTIONS)
    @patch("navigator.detect_screen")
    def test_advances_through_screens_then_stops(
        self, mock_detect, mock_load, mock_advance, mock_screenshot, mock_sleep
    ):
        sequence = iter(["gender", "orientation", "photos", "discover"])
        mock_detect.side_effect = lambda: self._make_screen(next(sequence, "discover"))
        navigator.run_navigation_loop(completed_screens={"discover"})
        # gender, orientation, photos, and discover are all advanced
        self.assertEqual(mock_advance.call_count, 4)
        mock_advance.assert_any_call("gender", _SCREEN_ACTIONS)
        mock_advance.assert_any_call("orientation", _SCREEN_ACTIONS)
        mock_advance.assert_any_call("photos", _SCREEN_ACTIONS)
        mock_advance.assert_any_call("discover", _SCREEN_ACTIONS)

    @patch("navigator.time.sleep")
    @patch("navigator.report_stuck")
    @patch("navigator.advance_screen")
    @patch("navigator.load_actions", return_value={})
    @patch("navigator.detect_screen")
    def test_reports_stuck_after_three_retries(
        self, mock_detect, mock_load, mock_advance, mock_stuck, mock_sleep
    ):
        mock_detect.return_value = self._make_screen("gender")
        mock_stuck.side_effect = SystemExit(1)
        with self.assertRaises(SystemExit):
            navigator.run_navigation_loop(completed_screens={"discover"})
        mock_stuck.assert_called_once_with("gender")

    @patch("navigator.time.sleep")
    @patch("navigator.take_screenshot")
    @patch("navigator.advance_screen")
    @patch("navigator.load_actions", return_value=_SCREEN_ACTIONS)
    @patch("navigator.detect_screen")
    def test_resets_retries_on_screen_change(
        self, mock_detect, mock_load, mock_advance, mock_screenshot, mock_sleep
    ):
        # gender appears twice (1 retry), then orientation, then discover
        sequence = iter(["gender", "gender", "orientation", "discover"])
        mock_detect.side_effect = lambda: self._make_screen(next(sequence, "discover"))
        navigator.run_navigation_loop(completed_screens={"discover"})
        # Should not have called report_stuck (only 1 retry < 3 limit)
        # gender twice + orientation + discover (terminal, actions run before exit)
        self.assertEqual(mock_advance.call_count, 4)
        mock_advance.assert_any_call("discover", _SCREEN_ACTIONS)

    @patch("navigator.time.sleep")
    @patch("navigator.take_screenshot")
    @patch("navigator.advance_screen")
    @patch("navigator.load_actions", return_value=_SCREEN_ACTIONS)
    @patch("navigator.detect_screen")
    def test_discover_explore_flow(
        self, mock_detect, mock_load, mock_advance, mock_screenshot, mock_sleep
    ):
        """discover actions run, then discover_explore is reached and exits."""
        sequence = iter(["discover", "discover_explore"])
        mock_detect.side_effect = lambda: self._make_screen(next(sequence, "discover_explore"))
        navigator.run_navigation_loop(completed_screens={"discover_explore"})
        # Both discover and discover_explore should have their actions executed
        self.assertEqual(mock_advance.call_count, 2)
        mock_advance.assert_any_call("discover", _SCREEN_ACTIONS)
        mock_advance.assert_any_call("discover_explore", _SCREEN_ACTIONS)


# ---------------------------------------------------------------------------
# load_actions (integration-style: reads the real actions.yaml)
# ---------------------------------------------------------------------------

class TestLoadActions(unittest.TestCase):
    def test_loads_yaml_file(self):
        actions = navigator.load_actions()
        self.assertIsInstance(actions, dict)

    def test_gender_screen_present(self):
        actions = navigator.load_actions()
        self.assertIn("gender", actions)

    def test_gender_has_tap_man(self):
        actions = navigator.load_actions()
        gender_actions = actions["gender"]["actions"]
        self.assertTrue(
            any(a.get("type") == "tap" and a.get("target") == "Man" for a in gender_actions),
            "Expected a 'tap Man' action in gender screen config",
        )

    def test_discover_has_screenshot(self):
        actions = navigator.load_actions()
        discover_actions = actions["discover"]["actions"]
        self.assertTrue(
            any(a.get("type") == "screenshot" for a in discover_actions),
            "Expected a 'screenshot' action in discover screen config",
        )

    def test_discover_explore_present(self):
        actions = navigator.load_actions()
        self.assertIn("discover_explore", actions)

    def test_discover_explore_has_screenshot(self):
        actions = navigator.load_actions()
        explore_actions = actions["discover_explore"]["actions"]
        self.assertTrue(
            any(a.get("type") == "screenshot" for a in explore_actions),
            "Expected a 'screenshot' action in discover_explore screen config",
        )

    def test_discover_has_tap_discovery_filters(self):
        actions = navigator.load_actions()
        discover_actions = actions["discover"]["actions"]
        self.assertTrue(
            any(
                a.get("type") == "tap" and a.get("target") == "Discovery Filters"
                for a in discover_actions
            ),
            "Expected a 'tap Discovery Filters' action in discover screen config",
        )

    def test_orientation_has_skip(self):
        actions = navigator.load_actions()
        orientation_actions = actions["orientation"]["actions"]
        self.assertTrue(
            any(a.get("type") == "skip" for a in orientation_actions),
            "Expected a 'skip' action in orientation screen config",
        )

    def test_photos_has_skip_photos(self):
        actions = navigator.load_actions()
        photos_actions = actions["photos"]["actions"]
        self.assertTrue(
            any(
                a.get("type") == "tap" and a.get("target") == "Skip Photos"
                for a in photos_actions
            ),
            "Expected a 'tap Skip Photos' action in photos screen config",
        )


if __name__ == "__main__":
    unittest.main()
