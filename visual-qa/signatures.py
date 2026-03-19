"""Screen signatures module for the DejTing mobile app.

Parses uiautomator dump XML output and identifies which app screen is
currently displayed by matching content-desc text against known screen
signature patterns.

Usage
-----
    from signatures import detect_screen

    with open("ui_dump.xml") as f:
        xml_text = f.read()

    match = detect_screen(xml_text)
    if match:
        print(match.screen, match.confidence, match.category)
"""

from __future__ import annotations

import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from typing import Literal

ScreenCategory = Literal["wizard", "main", "permission", "error"]

# ---------------------------------------------------------------------------
# Screen signature dictionary
# ---------------------------------------------------------------------------
# Each entry maps a screen name to:
#   "required" — list of content-desc substrings that MUST ALL be present
#   "category" — one of: wizard | main | permission | error
#
# Matching uses case-insensitive substring search, so the tokens are
# intentionally short and robust to minor copy changes.
# ---------------------------------------------------------------------------
SCREEN_SIGNATURES: dict[str, dict] = {
    # ── Pre-auth / auth ────────────────────────────────────────────────────
    "welcome": {
        "required": ["I'm ready to match", "Sign in"],
        "category": "main",
    },
    "login": {
        "required": ["Find your perfect match", "Continue with Phone Number"],
        "category": "main",
    },
    "account_consent": {
        "required": ["Choose an account", "DejTing"],
        "category": "main",
    },
    # ── Onboarding wizard ──────────────────────────────────────────────────
    "phone_entry": {
        "required": ["Can we get your number?", "Continue"],
        "category": "wizard",
    },
    "sms_code": {
        "required": ["verification code", "Resend code"],
        "category": "wizard",
    },
    "community_guidelines": {
        "required": ["Welcome to DejTing.", "House Rules", "I agree"],
        "category": "wizard",
    },
    "first_name": {
        "required": ["What's your first name?", "First name"],
        "category": "wizard",
    },
    "birthday": {
        "required": ["Your birthday?", "Month", "Day", "Year"],
        "category": "wizard",
    },
    "gender": {
        "required": ["gender", "Man", "Woman", "Non-binary"],
        "category": "wizard",
    },
    "orientation": {
        "required": ["orientation", "Straight", "Gay"],
        "category": "wizard",
    },
    "match_preferences": {
        "required": ["Show me", "Men", "Women", "Everyone"],
        "category": "wizard",
    },
    "photos": {
        "required": ["Add photos", "Add at least 2 photos"],
        "category": "wizard",
    },
    "interests": {
        "required": ["What are you into?"],
        "category": "wizard",
    },
    "about_me": {
        "required": ["makes you, you", "Communication Style"],
        "category": "wizard",
    },
    "lifestyle": {
        "required": ["Lifestyle habits"],
        "category": "wizard",
    },
    "relationship_goals": {
        "required": ["What are you", "looking for?", "Long-term"],
        "category": "wizard",
    },
    "age_range": {
        "required": ["How old is your ideal match?"],
        "category": "wizard",
    },
    "location_permission": {
        "required": ["Enable location", "location to show"],
        "category": "permission",
    },
    "notification_permission": {
        "required": ["Enable notifications", "Never miss a match"],
        "category": "permission",
    },
    "onboarding_complete": {
        "required": ["You're all set!", "Start Exploring"],
        "category": "wizard",
    },
    # ── Main app ───────────────────────────────────────────────────────────
    "discover": {
        # "Skip" and "Like" action buttons are unique to the discover card stack
        "required": ["Discover", "Skip", "Like"],
        "category": "main",
    },
    "matches": {
        "required": ["Matches", "Messages"],
        "category": "main",
    },
    "chat": {
        "required": ["Type a message..."],
        "category": "main",
    },
    "profile_hub": {
        "required": ["Get Verified", "Safety"],
        "category": "main",
    },
    "settings": {
        "required": ["Settings", "Logout"],
        "category": "main",
    },
    "verification_selfie": {
        "required": ["Verify your identity", "Take a Selfie"],
        "category": "main",
    },
    "photo_upload": {
        "required": ["Add photos", "Photo Tips"],
        "category": "main",
    },
    "profile_detail": {
        "required": ["Send a Message", "Report Profile"],
        "category": "main",
    },
    "voice_prompt": {
        "required": ["Voice Prompt", "Record a short voice intro"],
        "category": "main",
    },
}


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class ScreenMatch:
    """Result of a screen detection attempt."""

    screen: str
    confidence: float  # 0.0 – 1.0  (matched / total required tokens)
    category: ScreenCategory
    matched_tokens: list[str] = field(default_factory=list)

    def __repr__(self) -> str:  # pragma: no cover
        pct = int(self.confidence * 100)
        return (
            f"ScreenMatch(screen={self.screen!r}, confidence={pct}%, "
            f"category={self.category!r})"
        )


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _extract_content_descs(xml_text: str) -> list[str]:
    """Return all non-empty content-desc values from a uiautomator XML dump."""
    root = ET.fromstring(xml_text)
    return [
        node.get("content-desc", "")
        for node in root.iter()
        if node.get("content-desc", "").strip()
    ]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def detect_screen(xml_text: str) -> ScreenMatch | None:
    """Detect which app screen is currently shown.

    Parameters
    ----------
    xml_text:
        Raw XML string from ``adb shell uiautomator dump /dev/stdout``.

    Returns
    -------
    The best-matching :class:`ScreenMatch`, or ``None`` when no screen
    signature reached a non-zero confidence.

    Notes
    -----
    Confidence is computed as ``matched_tokens / total_required_tokens`` for
    each candidate, so a screen that matches all its tokens scores 1.0.
    When multiple candidates tie on confidence, the one with the most matched
    tokens wins (i.e., signatures with more required tokens are preferred).
    """
    descs = _extract_content_descs(xml_text)
    all_text = "\n".join(descs)

    candidates: list[ScreenMatch] = []
    for screen_name, spec in SCREEN_SIGNATURES.items():
        required: list[str] = spec["required"]
        matched = [tok for tok in required if tok.lower() in all_text.lower()]
        if not matched:
            continue
        confidence = len(matched) / len(required)
        candidates.append(
            ScreenMatch(
                screen=screen_name,
                confidence=confidence,
                category=spec["category"],
                matched_tokens=matched,
            )
        )

    if not candidates:
        return None

    # Highest confidence wins; break ties by number of matched tokens.
    return max(candidates, key=lambda m: (m.confidence, len(m.matched_tokens)))
