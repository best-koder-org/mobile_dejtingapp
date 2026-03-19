#!/usr/bin/env python3
"""
Visual QA — Layer 3: Regression Detection

Compares current walkthrough captures against known-good baselines to detect
visual regressions and unexpected screen changes.

Two comparison strategies:
  A) UI tree diff (primary) — structural comparison of uiautomator XML dumps.
     Ignores pixel-level rendering differences; catches missing elements,
     changed text, reordered widgets, new/removed buttons.
  B) Screenshot diff (secondary, opt-in via --ssim) — perceptual hash
     comparison using Pillow. Catches colour/spacing/icon changes.

Usage:
  # Compare all screens that have baselines
  python compare.py --all

  # Compare specific screens
  python compare.py gender orientation birthday

  # Also run screenshot diff
  python compare.py --all --ssim

  # Point at custom directories
  python compare.py --all \\
      --baselines path/to/baselines \\
      --captures  path/to/captures

Exit codes:
  0 — all screens passed
  1 — one or more regressions detected
  2 — no screens compared (missing captures or baselines)
"""

from __future__ import annotations

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Optional Pillow import for screenshot diff
# ---------------------------------------------------------------------------
try:
    from PIL import Image  # type: ignore

    _PILLOW_AVAILABLE = True
except ImportError:
    _PILLOW_AVAILABLE = False

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
_SCRIPT_DIR = Path(__file__).parent
DEFAULT_BASELINES_DIR = _SCRIPT_DIR / "baselines"
DEFAULT_CAPTURES_DIR = _SCRIPT_DIR / "captures"

# Similarity threshold below which a screenshot diff is flagged (0–1 scale).
# 1.0 = identical; lower values tolerate more pixel variation.
SSIM_THRESHOLD = 0.95


# ---------------------------------------------------------------------------
# XML helpers
# ---------------------------------------------------------------------------

def extract_labels(xml_string: str) -> set[str]:
    """Return all non-empty *text* and *content-desc* values from a uiautomator XML dump.

    Both attributes are considered because Flutter's accessibility bridge
    may use either one depending on the widget type and SDK version.
    """
    labels: set[str] = set()
    try:
        root = ET.fromstring(xml_string)
    except ET.ParseError as exc:
        raise ValueError(f"Invalid uiautomator XML: {exc}") from exc

    for node in root.iter("node"):
        for attr in ("text", "content-desc"):
            value = node.get(attr, "").strip()
            if value:
                labels.add(value)
    return labels


def diff_ui_trees(baseline_xml: str, current_xml: str) -> dict:
    """Compare two uiautomator XML dumps.

    Returns a dict with:
      added   — labels present in *current* but not in *baseline*
      removed — labels present in *baseline* but not in *current*
      changed — True when added or removed is non-empty
    """
    baseline_labels = extract_labels(baseline_xml)
    current_labels = extract_labels(current_xml)

    added = current_labels - baseline_labels
    removed = baseline_labels - current_labels

    return {
        "added": added,
        "removed": removed,
        "changed": bool(added or removed),
    }


# ---------------------------------------------------------------------------
# Screenshot helpers
# ---------------------------------------------------------------------------

def _avg_hash(image: "Image.Image", hash_size: int = 8) -> int:
    """Compute an average-hash (aHash) for *image*.

    Resize to *hash_size* × *hash_size*, convert to grayscale, threshold at
    the mean, and pack bits into an integer.
    """
    img = image.convert("L").resize((hash_size, hash_size), Image.LANCZOS)
    pixels = list(img.tobytes())
    mean = sum(pixels) / len(pixels)
    bits = [1 if p >= mean else 0 for p in pixels]
    hash_int = 0
    for bit in bits:
        hash_int = (hash_int << 1) | bit
    return hash_int


def _hamming_distance(a: int, b: int) -> int:
    """Return the number of differing bits between two integers."""
    return bin(a ^ b).count("1")


def screenshot_similarity(baseline_path: str | Path, current_path: str | Path) -> float:
    """Compare two PNG screenshots using average hash.

    Returns a similarity score in [0.0, 1.0] where 1.0 means identical.
    Raises RuntimeError if Pillow is not installed.
    """
    if not _PILLOW_AVAILABLE:
        raise RuntimeError(
            "Pillow is required for screenshot comparison. "
            "Install it with: pip install Pillow"
        )

    hash_size = 16  # 256-bit hash for finer granularity
    total_bits = hash_size * hash_size

    baseline_img = Image.open(str(baseline_path))
    current_img = Image.open(str(current_path))

    h_baseline = _avg_hash(baseline_img, hash_size)
    h_current = _avg_hash(current_img, hash_size)

    distance = _hamming_distance(h_baseline, h_current)
    return 1.0 - distance / total_bits


# ---------------------------------------------------------------------------
# Per-screen result
# ---------------------------------------------------------------------------

@dataclass
class ScreenResult:
    screen: str
    passed: bool
    xml_added: set[str] = field(default_factory=set)
    xml_removed: set[str] = field(default_factory=set)
    ssim_score: Optional[float] = None
    ssim_flagged: bool = False
    error: Optional[str] = None

    @property
    def skipped(self) -> bool:
        return self.error is not None


# ---------------------------------------------------------------------------
# Core comparison logic
# ---------------------------------------------------------------------------

def compare_screen(
    screen: str,
    baselines_dir: Path,
    captures_dir: Path,
    use_ssim: bool = False,
) -> ScreenResult:
    """Compare a single screen against its baseline.

    Returns a ScreenResult describing what (if anything) changed.
    """
    baseline_xml_path = baselines_dir / f"{screen}.xml"
    current_xml_path = captures_dir / f"{screen}.xml"

    # Validate required files exist
    if not baseline_xml_path.exists():
        return ScreenResult(
            screen=screen,
            passed=False,
            error=f"Baseline XML not found: {baseline_xml_path}",
        )
    if not current_xml_path.exists():
        return ScreenResult(
            screen=screen,
            passed=False,
            error=f"Capture XML not found: {current_xml_path}",
        )

    # UI tree diff
    try:
        diff = diff_ui_trees(
            baseline_xml_path.read_text(encoding="utf-8"),
            current_xml_path.read_text(encoding="utf-8"),
        )
    except ValueError as exc:
        return ScreenResult(screen=screen, passed=False, error=str(exc))

    result = ScreenResult(
        screen=screen,
        passed=not diff["changed"],
        xml_added=diff["added"],
        xml_removed=diff["removed"],
    )

    # Optional screenshot diff
    if use_ssim:
        baseline_png = baselines_dir / f"{screen}.png"
        current_png = captures_dir / f"{screen}.png"

        if not baseline_png.exists():
            result.error = (result.error or "") + f" Screenshot baseline missing: {baseline_png}"
        elif not current_png.exists():
            result.error = (result.error or "") + f" Screenshot capture missing: {current_png}"
        else:
            try:
                score = screenshot_similarity(baseline_png, current_png)
                result.ssim_score = score
                if score < SSIM_THRESHOLD:
                    result.ssim_flagged = True
                    result.passed = False
            except RuntimeError as exc:
                result.error = (result.error or "") + f" Screenshot diff skipped: {exc}"

    return result


def discover_screens(baselines_dir: Path) -> list[str]:
    """Return sorted list of screen names that have a baseline XML."""
    return sorted(
        p.stem for p in baselines_dir.glob("*.xml") if p.is_file()
    )


def run_comparison(
    screens: list[str],
    baselines_dir: Path,
    captures_dir: Path,
    use_ssim: bool = False,
) -> list[ScreenResult]:
    """Run comparison for all specified screens and return results."""
    return [
        compare_screen(screen, baselines_dir, captures_dir, use_ssim)
        for screen in screens
    ]


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

def print_report(results: list[ScreenResult]) -> int:
    """Print the Visual QA report.

    Returns exit code: 0 = all passed, 1 = regressions found, 2 = nothing compared.
    """
    today = date.today().strftime("%Y-%m-%d")
    width = 40
    print(f"\nVisual QA Report — {today}")
    print("=" * width)

    if not results:
        print("No screens compared.")
        return 2

    passed_count = 0
    for r in results:
        if r.skipped:
            status = f"SKIP — {r.error}"
        elif r.passed:
            status = "PASS (0 diffs)"
            passed_count += 1
        else:
            parts: list[str] = []
            if r.xml_removed:
                parts.append("removed: " + ", ".join(f"'{s}'" for s in sorted(r.xml_removed)))
            if r.xml_added:
                parts.append("added: " + ", ".join(f"'{s}'" for s in sorted(r.xml_added)))
            if r.ssim_flagged and r.ssim_score is not None:
                parts.append(f"screenshot similarity: {r.ssim_score:.2%}")
            if r.error:
                parts.append(r.error.strip())
            status = "FAIL — " + "; ".join(parts) if parts else "FAIL"

        print(f"{r.screen:<20} {status}")

    total = len(results)
    skipped = sum(1 for r in results if r.skipped)
    compared = total - skipped
    failed = compared - passed_count

    print("-" * width)
    if skipped:
        print(f"TOTAL: {passed_count}/{compared} screens passed, {failed} regression(s), {skipped} skipped")
    else:
        print(f"TOTAL: {passed_count}/{compared} screens passed, {failed} regression(s)")

    if failed > 0:
        print("\nTo accept current output as new baseline:")
        failing = [r.screen for r in results if not r.passed and not r.skipped]
        print(f"  python update_baselines.py {' '.join(failing)}")

    return 0 if failed == 0 else 1


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Compare Visual QA captures against baselines.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "screens",
        nargs="*",
        metavar="SCREEN",
        help="Screens to compare (omit to use --all).",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        dest="all_screens",
        help="Compare every screen that has a baseline XML.",
    )
    parser.add_argument(
        "--ssim",
        action="store_true",
        help="Also compare screenshots using perceptual hash (requires Pillow).",
    )
    parser.add_argument(
        "--baselines",
        type=Path,
        default=DEFAULT_BASELINES_DIR,
        metavar="DIR",
        help=f"Baselines directory (default: {DEFAULT_BASELINES_DIR}).",
    )
    parser.add_argument(
        "--captures",
        type=Path,
        default=DEFAULT_CAPTURES_DIR,
        metavar="DIR",
        help=f"Captures directory (default: {DEFAULT_CAPTURES_DIR}).",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    baselines_dir: Path = args.baselines
    captures_dir: Path = args.captures

    if not baselines_dir.exists():
        print(f"Error: baselines directory not found: {baselines_dir}", file=sys.stderr)
        return 2

    # Determine which screens to compare
    if args.all_screens:
        screens = discover_screens(baselines_dir)
        if not screens:
            print(f"No baseline XML files found in {baselines_dir}", file=sys.stderr)
            return 2
    elif args.screens:
        screens = args.screens
    else:
        parser.print_help()
        return 2

    results = run_comparison(screens, baselines_dir, captures_dir, use_ssim=args.ssim)
    return print_report(results)


if __name__ == "__main__":
    sys.exit(main())
