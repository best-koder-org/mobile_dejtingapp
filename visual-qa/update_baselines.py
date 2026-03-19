#!/usr/bin/env python3
"""
Visual QA — Baseline Updater

Copies current captures (XML and, if present, PNG) into the baselines
directory, accepting them as the new known-good reference.

Usage:
  # Update specific screens
  python update_baselines.py gender orientation birthday

  # Update all screens that have captures
  python update_baselines.py --all

  # Dry-run: show what would be updated without writing
  python update_baselines.py --all --dry-run

  # Custom directories
  python update_baselines.py --all \\
      --baselines path/to/baselines \\
      --captures  path/to/captures
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).parent
DEFAULT_BASELINES_DIR = _SCRIPT_DIR / "baselines"
DEFAULT_CAPTURES_DIR = _SCRIPT_DIR / "captures"


def discover_captured_screens(captures_dir: Path) -> list[str]:
    """Return sorted list of screen names that have a capture XML in *captures_dir*."""
    return sorted(p.stem for p in captures_dir.glob("*.xml") if p.is_file())


def update_baseline(
    screen: str,
    baselines_dir: Path,
    captures_dir: Path,
    dry_run: bool = False,
) -> tuple[bool, str]:
    """Copy *screen* XML (and PNG if present) from captures to baselines.

    Returns (success, message).
    """
    xml_src = captures_dir / f"{screen}.xml"
    xml_dst = baselines_dir / f"{screen}.xml"
    png_src = captures_dir / f"{screen}.png"
    png_dst = baselines_dir / f"{screen}.png"

    if not xml_src.exists():
        return False, f"No capture XML found: {xml_src}"

    if not dry_run:
        baselines_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(xml_src, xml_dst)

    updated = [f"{screen}.xml"]

    if png_src.exists():
        if not dry_run:
            shutil.copy2(png_src, png_dst)
        updated.append(f"{screen}.png")

    verb = "Would update" if dry_run else "Updated"
    return True, f"{verb}: {', '.join(updated)}"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Accept current Visual QA captures as new baselines.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "screens",
        nargs="*",
        metavar="SCREEN",
        help="Screen name(s) to update (omit to use --all).",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        dest="all_screens",
        help="Update every screen that has a capture XML.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be updated without writing any files.",
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

    if not captures_dir.exists():
        print(f"Error: captures directory not found: {captures_dir}", file=sys.stderr)
        return 1

    if args.all_screens:
        screens = discover_captured_screens(captures_dir)
        if not screens:
            print(f"No capture XML files found in {captures_dir}", file=sys.stderr)
            return 1
    elif args.screens:
        screens = args.screens
    else:
        parser.print_help()
        return 1

    if args.dry_run:
        print("[dry-run] No files will be written.\n")

    success_count = 0
    for screen in screens:
        ok, msg = update_baseline(screen, baselines_dir, captures_dir, dry_run=args.dry_run)
        icon = "✓" if ok else "✗"
        print(f"  {icon}  {screen:<20} {msg}")
        if ok:
            success_count += 1

    print(f"\n{success_count}/{len(screens)} baseline(s) updated.")

    if not args.dry_run and success_count > 0:
        print("\nRemember to commit the updated baselines:")
        print(f"  git add {baselines_dir}")
        print("  git commit -m 'visual-qa: update baselines'")

    return 0 if success_count == len(screens) else 1


if __name__ == "__main__":
    sys.exit(main())
