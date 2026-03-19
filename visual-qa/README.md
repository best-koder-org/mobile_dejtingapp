# Visual QA — Layer 3: Regression Detection

Compares UI tree dumps and screenshots captured during an automated walkthrough
against known-good baselines to detect visual regressions.

## Quick Start

```bash
cd visual-qa
pip install -r requirements.txt

# Run a full walkthrough first (Layer 2) to populate captures/
# Then compare every screen:
python compare.py --all

# Compare specific screens:
python compare.py gender orientation birthday

# Also diff screenshots (requires Pillow):
python compare.py --all --ssim
```

## Directory Layout

```
visual-qa/
  compare.py            # UI tree diff + optional screenshot diff
  update_baselines.py   # Accept current captures as new baselines
  requirements.txt      # Python dependencies (pytest, Pillow)
  baselines/            # Known-good references (committed to git)
    gender.xml          # uiautomator XML dump
    gender.png          # Screenshot (binary, not committed by default)
    orientation.xml
    orientation.png
    ...
  captures/             # Output from latest walkthrough run (git-ignored)
    gender.xml
    gender.png
    ...
  tests/
    test_compare.py     # Unit tests for compare.py
```

## Workflow

### Normal run (detect regressions)

1. Run your automated walkthrough to populate `captures/`
2. Run `python compare.py --all`
3. Review the report — any `FAIL` line means a regression was detected

### Accepting intentional changes

When a screen changes on purpose:

```bash
# Review the diff first:
python compare.py gender discover

# Then accept the new output as the baseline:
python update_baselines.py gender discover

# Commit the updated baselines:
git add baselines/
git commit -m "visual-qa: update baselines after redesign"
```

### Updating all screens at once

```bash
python update_baselines.py --all
```

## Comparison Strategies

### Strategy A: UI Tree Diff (primary)

Parses uiautomator XML dumps and compares the set of text labels / 
content-desc values. This is fast, deterministic, and ignores pixel-level
rendering differences (font smoothing, sub-pixel antialiasing).

Catches:
- Missing or renamed buttons
- Changed heading text
- Reordered or removed widgets
- New dialogs or permission prompts

### Strategy B: Screenshot Diff (secondary, opt-in)

Uses a perceptual average hash to compare screenshots. Enable with `--ssim`.

```bash
python compare.py --all --ssim
```

Catches:
- Color changes, spacing regressions, icon swaps

More brittle than the XML diff — minor rendering differences across
emulator versions can cause false positives. Use as a supplementary check.

## Sample Report

```
Visual QA Report — 2026-03-18
========================================
welcome              PASS (0 diffs)
phone_entry          PASS (0 diffs)
sms_code             PASS (0 diffs)
community_guidelines PASS (0 diffs)
first_name           PASS (0 diffs)
birthday             FAIL — removed: 'Next'; added: 'Skip'
gender               PASS (0 diffs)
orientation          PASS (0 diffs)
...
----------------------------------------
TOTAL: 20/21 screens passed, 1 regression(s)

To accept current output as new baseline:
  python update_baselines.py birthday
```

## Running Tests

```bash
cd visual-qa
pytest tests/ -v
```

## Baseline PNGs

PNG baselines are large binary files. They are **not** committed to git by
default (see `.gitignore`). To initialise them after a first walkthrough run:

```bash
python update_baselines.py --all
git add baselines/*.png
git commit -m "visual-qa: add initial screenshot baselines"
```
