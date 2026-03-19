"""
Unit tests for visual-qa/compare.py
"""

from __future__ import annotations

import io
import sys
import tempfile
import textwrap
from pathlib import Path
from unittest.mock import patch

import pytest

# Make the parent directory importable so we can do `from compare import …`
sys.path.insert(0, str(Path(__file__).parent.parent))

from compare import (  # noqa: E402
    ScreenResult,
    compare_screen,
    diff_ui_trees,
    discover_screens,
    extract_labels,
    print_report,
    run_comparison,
    screenshot_similarity,
    _PILLOW_AVAILABLE,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_BASELINE_XML = textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <hierarchy rotation="0">
      <node index="0" text="" resource-id="" class="android.widget.FrameLayout"
            package="com.dejtingapp.app" content-desc="" checkable="false"
            checked="false" clickable="false" enabled="true" focusable="false"
            focused="false" scrollable="false" long-clickable="false"
            password="false" selected="false" bounds="[0,0][1080,2340]">
        <node index="0" text="What's your gender?" resource-id=""
              class="android.view.View" content-desc="What's your gender?"
              checkable="false" checked="false" clickable="false" enabled="true"
              focusable="false" focused="false" scrollable="false"
              long-clickable="false" password="false" selected="false"
              bounds="[0,0][1080,200]"/>
        <node index="1" text="Man" resource-id="" class="android.view.View"
              content-desc="Man" checkable="false" checked="false"
              clickable="true" enabled="true" focusable="true" focused="false"
              scrollable="false" long-clickable="false" password="false"
              selected="false" bounds="[0,200][1080,254]"/>
        <node index="2" text="Woman" resource-id="" class="android.view.View"
              content-desc="Woman" checkable="false" checked="false"
              clickable="true" enabled="true" focusable="true" focused="false"
              scrollable="false" long-clickable="false" password="false"
              selected="false" bounds="[0,266][1080,320]"/>
        <node index="3" text="More options" resource-id=""
              class="android.view.View" content-desc="More options"
              checkable="false" checked="false" clickable="true" enabled="true"
              focusable="true" focused="false" scrollable="false"
              long-clickable="false" password="false" selected="false"
              bounds="[0,332][1080,386]"/>
        <node index="4" text="Show gender on profile" resource-id=""
              class="android.view.View" content-desc="Show gender on profile"
              checkable="true" checked="false" clickable="true" enabled="true"
              focusable="true" focused="false" scrollable="false"
              long-clickable="false" password="false" selected="false"
              bounds="[0,400][1080,440]"/>
        <node index="5" text="Next" resource-id="" class="android.view.View"
              content-desc="Next" checkable="false" checked="false"
              clickable="true" enabled="false" focusable="true" focused="false"
              scrollable="false" long-clickable="false" password="false"
              selected="false" bounds="[0,2286][1080,2340]"/>
      </node>
    </hierarchy>
""")

# Same as baseline but "Next" button removed and "Skip" added
_REGRESSED_XML = textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <hierarchy rotation="0">
      <node index="0" text="" resource-id="" class="android.widget.FrameLayout"
            package="com.dejtingapp.app" content-desc="" checkable="false"
            checked="false" clickable="false" enabled="true" focusable="false"
            focused="false" scrollable="false" long-clickable="false"
            password="false" selected="false" bounds="[0,0][1080,2340]">
        <node index="0" text="What's your gender?" resource-id=""
              class="android.view.View" content-desc="What's your gender?"
              checkable="false" checked="false" clickable="false" enabled="true"
              focusable="false" focused="false" scrollable="false"
              long-clickable="false" password="false" selected="false"
              bounds="[0,0][1080,200]"/>
        <node index="1" text="Man" resource-id="" class="android.view.View"
              content-desc="Man" checkable="false" checked="false"
              clickable="true" enabled="true" focusable="true" focused="false"
              scrollable="false" long-clickable="false" password="false"
              selected="false" bounds="[0,200][1080,254]"/>
        <node index="2" text="Woman" resource-id="" class="android.view.View"
              content-desc="Woman" checkable="false" checked="false"
              clickable="true" enabled="true" focusable="true" focused="false"
              scrollable="false" long-clickable="false" password="false"
              selected="false" bounds="[0,266][1080,320]"/>
        <node index="3" text="More options" resource-id=""
              class="android.view.View" content-desc="More options"
              checkable="false" checked="false" clickable="true" enabled="true"
              focusable="true" focused="false" scrollable="false"
              long-clickable="false" password="false" selected="false"
              bounds="[0,332][1080,386]"/>
        <node index="4" text="Show gender on profile" resource-id=""
              class="android.view.View" content-desc="Show gender on profile"
              checkable="true" checked="false" clickable="true" enabled="true"
              focusable="true" focused="false" scrollable="false"
              long-clickable="false" password="false" selected="false"
              bounds="[0,400][1080,440]"/>
        <node index="5" text="Skip" resource-id="" class="android.view.View"
              content-desc="Skip" checkable="false" checked="false"
              clickable="true" enabled="true" focusable="true" focused="false"
              scrollable="false" long-clickable="false" password="false"
              selected="false" bounds="[0,2286][1080,2340]"/>
      </node>
    </hierarchy>
""")

_IDENTICAL_XML = _BASELINE_XML  # unchanged capture


# ---------------------------------------------------------------------------
# extract_labels
# ---------------------------------------------------------------------------

class TestExtractLabels:
    def test_extracts_text_and_content_desc(self):
        labels = extract_labels(_BASELINE_XML)
        assert "What's your gender?" in labels
        assert "Man" in labels
        assert "Woman" in labels
        assert "More options" in labels
        assert "Show gender on profile" in labels
        assert "Next" in labels

    def test_empty_strings_excluded(self):
        labels = extract_labels(_BASELINE_XML)
        assert "" not in labels

    def test_minimal_xml(self):
        xml = '<?xml version="1.0"?><hierarchy rotation="0"><node text="Hello" content-desc="" /></hierarchy>'
        labels = extract_labels(xml)
        assert labels == {"Hello"}

    def test_invalid_xml_raises(self):
        with pytest.raises(ValueError, match="Invalid uiautomator XML"):
            extract_labels("not xml at all <><")

    def test_deduplicates_labels(self):
        # Same text appears in both text and content-desc
        xml = '<?xml version="1.0"?><hierarchy><node text="Next" content-desc="Next" /></hierarchy>'
        labels = extract_labels(xml)
        assert labels == {"Next"}

    def test_whitespace_stripped(self):
        xml = '<?xml version="1.0"?><hierarchy><node text="  Hello  " content-desc=" " /></hierarchy>'
        labels = extract_labels(xml)
        assert "Hello" in labels
        assert " " not in labels


# ---------------------------------------------------------------------------
# diff_ui_trees
# ---------------------------------------------------------------------------

class TestDiffUiTrees:
    def test_identical_trees_no_diff(self):
        result = diff_ui_trees(_BASELINE_XML, _IDENTICAL_XML)
        assert result["added"] == set()
        assert result["removed"] == set()
        assert result["changed"] is False

    def test_detects_removed_element(self):
        result = diff_ui_trees(_BASELINE_XML, _REGRESSED_XML)
        assert "Next" in result["removed"]
        assert result["changed"] is True

    def test_detects_added_element(self):
        result = diff_ui_trees(_BASELINE_XML, _REGRESSED_XML)
        assert "Skip" in result["added"]
        assert result["changed"] is True

    def test_removed_and_added_together(self):
        result = diff_ui_trees(_BASELINE_XML, _REGRESSED_XML)
        assert "Next" in result["removed"]
        assert "Skip" in result["added"]

    def test_invalid_baseline_raises(self):
        with pytest.raises(ValueError):
            diff_ui_trees("bad xml", _BASELINE_XML)

    def test_invalid_current_raises(self):
        with pytest.raises(ValueError):
            diff_ui_trees(_BASELINE_XML, "bad xml")


# ---------------------------------------------------------------------------
# compare_screen (file-based)
# ---------------------------------------------------------------------------

class TestCompareScreen:
    def _write(self, directory: Path, name: str, content: str) -> None:
        (directory / name).write_text(content, encoding="utf-8")

    def test_pass_when_identical(self, tmp_path):
        baselines = tmp_path / "baselines"
        captures = tmp_path / "captures"
        baselines.mkdir()
        captures.mkdir()
        self._write(baselines, "gender.xml", _BASELINE_XML)
        self._write(captures, "gender.xml", _IDENTICAL_XML)

        result = compare_screen("gender", baselines, captures)
        assert result.passed is True
        assert result.xml_added == set()
        assert result.xml_removed == set()
        assert result.error is None

    def test_fail_when_regressed(self, tmp_path):
        baselines = tmp_path / "baselines"
        captures = tmp_path / "captures"
        baselines.mkdir()
        captures.mkdir()
        self._write(baselines, "gender.xml", _BASELINE_XML)
        self._write(captures, "gender.xml", _REGRESSED_XML)

        result = compare_screen("gender", baselines, captures)
        assert result.passed is False
        assert "Next" in result.xml_removed
        assert "Skip" in result.xml_added

    def test_skip_when_baseline_missing(self, tmp_path):
        baselines = tmp_path / "baselines"
        captures = tmp_path / "captures"
        baselines.mkdir()
        captures.mkdir()
        self._write(captures, "gender.xml", _BASELINE_XML)

        result = compare_screen("gender", baselines, captures)
        assert result.skipped is True
        assert "Baseline XML not found" in result.error

    def test_skip_when_capture_missing(self, tmp_path):
        baselines = tmp_path / "baselines"
        captures = tmp_path / "captures"
        baselines.mkdir()
        captures.mkdir()
        self._write(baselines, "gender.xml", _BASELINE_XML)

        result = compare_screen("gender", baselines, captures)
        assert result.skipped is True
        assert "Capture XML not found" in result.error

    def test_ssim_skipped_when_png_missing(self, tmp_path):
        baselines = tmp_path / "baselines"
        captures = tmp_path / "captures"
        baselines.mkdir()
        captures.mkdir()
        self._write(baselines, "gender.xml", _BASELINE_XML)
        self._write(captures, "gender.xml", _IDENTICAL_XML)
        # No PNG files written

        result = compare_screen("gender", baselines, captures, use_ssim=True)
        # XML passed but SSIM warned about missing baseline PNG
        assert result.error is not None
        assert "Screenshot baseline missing" in result.error


# ---------------------------------------------------------------------------
# discover_screens
# ---------------------------------------------------------------------------

class TestDiscoverScreens:
    def test_finds_xml_files(self, tmp_path):
        (tmp_path / "gender.xml").write_text("<hierarchy/>")
        (tmp_path / "birthday.xml").write_text("<hierarchy/>")
        (tmp_path / "gender.png").write_bytes(b"")  # PNG should be ignored

        screens = discover_screens(tmp_path)
        assert screens == ["birthday", "gender"]

    def test_empty_directory(self, tmp_path):
        screens = discover_screens(tmp_path)
        assert screens == []

    def test_returns_sorted(self, tmp_path):
        for name in ["z_screen", "a_screen", "m_screen"]:
            (tmp_path / f"{name}.xml").write_text("<hierarchy/>")

        screens = discover_screens(tmp_path)
        assert screens == sorted(screens)


# ---------------------------------------------------------------------------
# run_comparison
# ---------------------------------------------------------------------------

class TestRunComparison:
    def test_runs_all_requested_screens(self, tmp_path):
        baselines = tmp_path / "baselines"
        captures = tmp_path / "captures"
        baselines.mkdir()
        captures.mkdir()

        for screen in ["gender", "birthday", "orientation"]:
            (baselines / f"{screen}.xml").write_text(_BASELINE_XML)
            (captures / f"{screen}.xml").write_text(_BASELINE_XML)

        results = run_comparison(["gender", "birthday", "orientation"], baselines, captures)
        assert len(results) == 3
        assert all(r.passed for r in results)

    def test_mixed_pass_fail(self, tmp_path):
        baselines = tmp_path / "baselines"
        captures = tmp_path / "captures"
        baselines.mkdir()
        captures.mkdir()

        (baselines / "gender.xml").write_text(_BASELINE_XML)
        (captures / "gender.xml").write_text(_BASELINE_XML)  # identical → pass
        (baselines / "birthday.xml").write_text(_BASELINE_XML)
        (captures / "birthday.xml").write_text(_REGRESSED_XML)  # regressed → fail

        results = run_comparison(["gender", "birthday"], baselines, captures)
        gender_result = next(r for r in results if r.screen == "gender")
        birthday_result = next(r for r in results if r.screen == "birthday")

        assert gender_result.passed is True
        assert birthday_result.passed is False


# ---------------------------------------------------------------------------
# print_report
# ---------------------------------------------------------------------------

class TestPrintReport:
    def _capture(self, results: list[ScreenResult]) -> tuple[str, int]:
        buf = io.StringIO()
        with patch("sys.stdout", buf):
            code = print_report(results)
        return buf.getvalue(), code

    def test_all_pass_returns_0(self):
        results = [ScreenResult("gender", passed=True)]
        _, code = self._capture(results)
        assert code == 0

    def test_failure_returns_1(self):
        results = [
            ScreenResult("gender", passed=False, xml_removed={"Next"}, xml_added={"Skip"}),
        ]
        _, code = self._capture(results)
        assert code == 1

    def test_empty_results_returns_2(self):
        _, code = self._capture([])
        assert code == 2

    def test_report_contains_screen_name(self):
        results = [ScreenResult("birthday", passed=True)]
        output, _ = self._capture(results)
        assert "birthday" in output

    def test_report_shows_removed_labels(self):
        results = [
            ScreenResult("birthday", passed=False, xml_removed={"Next"}, xml_added=set()),
        ]
        output, _ = self._capture(results)
        assert "Next" in output
        assert "removed" in output

    def test_report_shows_added_labels(self):
        results = [
            ScreenResult("birthday", passed=False, xml_removed=set(), xml_added={"Skip"}),
        ]
        output, _ = self._capture(results)
        assert "Skip" in output
        assert "added" in output

    def test_report_shows_total(self):
        results = [
            ScreenResult("gender", passed=True),
            ScreenResult("birthday", passed=False, xml_removed={"Next"}, xml_added=set()),
        ]
        output, _ = self._capture(results)
        assert "1/2" in output

    def test_skipped_shown_in_report(self):
        results = [
            ScreenResult("missing_screen", passed=False, error="Baseline XML not found: x.xml"),
        ]
        output, _ = self._capture(results)
        assert "SKIP" in output

    def test_ssim_score_shown_when_flagged(self):
        results = [
            ScreenResult("discover", passed=False, ssim_score=0.85, ssim_flagged=True),
        ]
        output, _ = self._capture(results)
        assert "85.00%" in output or "85%" in output.replace("85.00%", "85%")

    def test_update_hint_shown_on_failure(self):
        results = [
            ScreenResult("gender", passed=False, xml_removed={"Next"}, xml_added=set()),
        ]
        output, _ = self._capture(results)
        assert "update_baselines.py" in output
        assert "gender" in output


# ---------------------------------------------------------------------------
# screenshot_similarity (only run when Pillow is available)
# ---------------------------------------------------------------------------

@pytest.mark.skipif(not _PILLOW_AVAILABLE, reason="Pillow not installed")
class TestScreenshotSimilarity:
    def _make_png(self, directory: Path, name: str, color: tuple) -> Path:
        from PIL import Image as PILImage

        img = PILImage.new("RGB", (100, 100), color)
        path = directory / name
        img.save(str(path))
        return path

    def test_identical_images_score_1(self, tmp_path):
        a = self._make_png(tmp_path, "a.png", (255, 0, 0))
        b = self._make_png(tmp_path, "b.png", (255, 0, 0))
        score = screenshot_similarity(a, b)
        assert score == 1.0

    def test_different_images_score_less_than_1(self, tmp_path):
        from PIL import Image as PILImage, ImageDraw

        # Image A: left half white, right half black
        img_a = PILImage.new("RGB", (100, 100), "black")
        ImageDraw.Draw(img_a).rectangle([0, 0, 49, 99], fill="white")
        path_a = tmp_path / "a.png"
        img_a.save(str(path_a))

        # Image B: left half black, right half white (inverse of A)
        img_b = PILImage.new("RGB", (100, 100), "white")
        ImageDraw.Draw(img_b).rectangle([0, 0, 49, 99], fill="black")
        path_b = tmp_path / "b.png"
        img_b.save(str(path_b))

        score = screenshot_similarity(path_a, path_b)
        assert 0.0 <= score < 1.0

    def test_score_range(self, tmp_path):
        a = self._make_png(tmp_path, "a.png", (100, 100, 100))
        b = self._make_png(tmp_path, "b.png", (200, 200, 200))
        score = screenshot_similarity(a, b)
        assert 0.0 <= score <= 1.0


@pytest.mark.skipif(_PILLOW_AVAILABLE, reason="Pillow is installed — skip this test")
class TestScreenshotSimilarityNoPillow:
    def test_raises_without_pillow(self, tmp_path):
        a = tmp_path / "a.png"
        a.write_bytes(b"")
        b = tmp_path / "b.png"
        b.write_bytes(b"")
        with pytest.raises(RuntimeError, match="Pillow is required"):
            screenshot_similarity(a, b)
