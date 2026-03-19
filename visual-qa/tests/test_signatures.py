"""Unit tests for the visual-qa screen signatures module.

Each test loads a fixture XML file (or builds a minimal inline XML snippet)
and asserts that ``detect_screen`` returns the expected screen name and
category.  Fixtures live in ``visual-qa/fixtures/``.
"""

import os
import sys
import unittest

# Allow running tests from any working directory.
_HERE = os.path.dirname(os.path.abspath(__file__))
_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _ROOT)

from signatures import (  # noqa: E402
    SCREEN_SIGNATURES,
    ScreenMatch,
    _extract_content_descs,
    detect_screen,
)

FIXTURES_DIR = os.path.join(_ROOT, "fixtures")


def _load(filename: str) -> str:
    """Load a fixture XML file and return its contents."""
    path = os.path.join(FIXTURES_DIR, filename)
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def _minimal_xml(*content_descs: str) -> str:
    """Build a minimal uiautomator-style XML containing the given content-descs."""
    nodes = "\n    ".join(
        f'<node content-desc="{cd}" text="{cd}" />' for cd in content_descs
    )
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        "<hierarchy>"
        f"\n    {nodes}\n"
        "</hierarchy>"
    )


# ---------------------------------------------------------------------------
# Fixture-based tests — one per screen
# ---------------------------------------------------------------------------


class TestFixtureWelcome(unittest.TestCase):
    def test_detects_welcome(self):
        result = detect_screen(_load("welcome.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "welcome")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureLogin(unittest.TestCase):
    def test_detects_login(self):
        result = detect_screen(_load("login.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "login")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureAccountConsent(unittest.TestCase):
    def test_detects_account_consent(self):
        result = detect_screen(_load("account_consent.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "account_consent")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixturePhoneEntry(unittest.TestCase):
    def test_detects_phone_entry(self):
        result = detect_screen(_load("phone_entry.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "phone_entry")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureSmsCode(unittest.TestCase):
    def test_detects_sms_code(self):
        result = detect_screen(_load("sms_code.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "sms_code")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureCommunityGuidelines(unittest.TestCase):
    def test_detects_community_guidelines(self):
        result = detect_screen(_load("community_guidelines.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "community_guidelines")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureFirstName(unittest.TestCase):
    def test_detects_first_name(self):
        result = detect_screen(_load("first_name.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "first_name")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureBirthday(unittest.TestCase):
    def test_detects_birthday(self):
        result = detect_screen(_load("birthday.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "birthday")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureGender(unittest.TestCase):
    def test_detects_gender(self):
        result = detect_screen(_load("gender.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "gender")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureOrientation(unittest.TestCase):
    def test_detects_orientation(self):
        result = detect_screen(_load("orientation.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "orientation")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureMatchPreferences(unittest.TestCase):
    def test_detects_match_preferences(self):
        result = detect_screen(_load("match_preferences.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "match_preferences")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixturePhotos(unittest.TestCase):
    def test_detects_photos(self):
        result = detect_screen(_load("photos.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "photos")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureInterests(unittest.TestCase):
    def test_detects_interests(self):
        result = detect_screen(_load("interests.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "interests")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureAboutMe(unittest.TestCase):
    def test_detects_about_me(self):
        result = detect_screen(_load("about_me.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "about_me")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureLifestyle(unittest.TestCase):
    def test_detects_lifestyle(self):
        result = detect_screen(_load("lifestyle.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "lifestyle")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureRelationshipGoals(unittest.TestCase):
    def test_detects_relationship_goals(self):
        result = detect_screen(_load("relationship_goals.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "relationship_goals")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureAgeRange(unittest.TestCase):
    def test_detects_age_range(self):
        result = detect_screen(_load("age_range.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "age_range")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureLocationPermission(unittest.TestCase):
    def test_detects_location_permission(self):
        result = detect_screen(_load("location_permission.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "location_permission")
        self.assertEqual(result.category, "permission")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureNotificationPermission(unittest.TestCase):
    def test_detects_notification_permission(self):
        result = detect_screen(_load("notification_permission.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "notification_permission")
        self.assertEqual(result.category, "permission")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureOnboardingComplete(unittest.TestCase):
    def test_detects_onboarding_complete(self):
        result = detect_screen(_load("onboarding_complete.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "onboarding_complete")
        self.assertEqual(result.category, "wizard")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureDiscover(unittest.TestCase):
    def test_detects_discover(self):
        result = detect_screen(_load("discover.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "discover")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureMatches(unittest.TestCase):
    def test_detects_matches(self):
        result = detect_screen(_load("matches.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "matches")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureChat(unittest.TestCase):
    def test_detects_chat(self):
        result = detect_screen(_load("chat.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "chat")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureProfileHub(unittest.TestCase):
    def test_detects_profile_hub(self):
        result = detect_screen(_load("profile_hub.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "profile_hub")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureSettings(unittest.TestCase):
    def test_detects_settings(self):
        result = detect_screen(_load("settings.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "settings")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureVerificationSelfie(unittest.TestCase):
    def test_detects_verification_selfie(self):
        result = detect_screen(_load("verification_selfie.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "verification_selfie")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixturePhotoUpload(unittest.TestCase):
    def test_detects_photo_upload(self):
        result = detect_screen(_load("photo_upload.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "photo_upload")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureProfileDetail(unittest.TestCase):
    def test_detects_profile_detail(self):
        result = detect_screen(_load("profile_detail.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "profile_detail")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestFixtureVoicePrompt(unittest.TestCase):
    def test_detects_voice_prompt(self):
        result = detect_screen(_load("voice_prompt.xml"))
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "voice_prompt")
        self.assertEqual(result.category, "main")
        self.assertAlmostEqual(result.confidence, 1.0)


# ---------------------------------------------------------------------------
# Inline / edge-case tests
# ---------------------------------------------------------------------------


class TestExtractContentDescs(unittest.TestCase):
    def test_returns_only_non_empty(self):
        xml = _minimal_xml("Hello", "World")
        descs = _extract_content_descs(xml)
        self.assertIn("Hello", descs)
        self.assertIn("World", descs)

    def test_ignores_empty_content_desc(self):
        xml = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            "<hierarchy>"
            '<node content-desc="" />'
            '<node content-desc="   " />'
            '<node content-desc="Visible" />'
            "</hierarchy>"
        )
        descs = _extract_content_descs(xml)
        self.assertEqual(descs, ["Visible"])


class TestDetectScreenNoMatch(unittest.TestCase):
    def test_returns_none_for_empty_screen(self):
        xml = _minimal_xml()
        result = detect_screen(xml)
        self.assertIsNone(result)

    def test_returns_none_for_unrecognised_content(self):
        xml = _minimal_xml("Lorem ipsum", "dolor sit amet", "consectetur")
        result = detect_screen(xml)
        self.assertIsNone(result)


class TestDetectScreenPartialMatch(unittest.TestCase):
    def test_partial_match_returns_confidence_less_than_one(self):
        # Gender screen needs: gender, Man, Woman, Non-binary
        # Provide only two of the four tokens.
        xml = _minimal_xml("gender", "Man")
        result = detect_screen(xml)
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "gender")
        self.assertLess(result.confidence, 1.0)
        self.assertGreater(result.confidence, 0.0)

    def test_matched_tokens_listed(self):
        xml = _minimal_xml("Lifestyle habits")
        result = detect_screen(xml)
        self.assertIsNotNone(result)
        self.assertIn("Lifestyle habits", result.matched_tokens)


class TestDetectScreenCaseInsensitive(unittest.TestCase):
    def test_case_insensitive_matching(self):
        # Tokens are matched case-insensitively.
        xml = _minimal_xml("LIFESTYLE HABITS")
        result = detect_screen(xml)
        self.assertIsNotNone(result)
        self.assertEqual(result.screen, "lifestyle")


class TestScreenMatchReturnsHighestConfidence(unittest.TestCase):
    def test_full_match_preferred_over_partial(self):
        # Build XML with all tokens for notification_permission
        # plus a single token that partially matches location_permission.
        xml = _minimal_xml(
            "Enable notifications",
            "Never miss a match",
            "Enable location",  # partial match for location_permission
        )
        result = detect_screen(xml)
        self.assertIsNotNone(result)
        # notification_permission has 2/2 = 1.0 confidence
        # location_permission has 1/2 = 0.5 confidence
        self.assertEqual(result.screen, "notification_permission")
        self.assertAlmostEqual(result.confidence, 1.0)


class TestScreenSignaturesDict(unittest.TestCase):
    """Validate the structure of SCREEN_SIGNATURES itself."""

    VALID_CATEGORIES = {"wizard", "main", "permission", "error"}

    def test_all_entries_have_required_key(self):
        for name, spec in SCREEN_SIGNATURES.items():
            with self.subTest(screen=name):
                self.assertIn("required", spec)
                self.assertIsInstance(spec["required"], list)
                self.assertGreater(len(spec["required"]), 0)

    def test_all_entries_have_valid_category(self):
        for name, spec in SCREEN_SIGNATURES.items():
            with self.subTest(screen=name):
                self.assertIn(spec["category"], self.VALID_CATEGORIES)

    def test_at_least_22_screens(self):
        self.assertGreaterEqual(len(SCREEN_SIGNATURES), 22)

    def test_screen_names_are_lowercase_underscore(self):
        import re

        pattern = re.compile(r"^[a-z][a-z0-9_]*$")
        for name in SCREEN_SIGNATURES:
            with self.subTest(screen=name):
                self.assertRegex(name, pattern)

    def test_all_tokens_are_non_empty_strings(self):
        for name, spec in SCREEN_SIGNATURES.items():
            for tok in spec["required"]:
                with self.subTest(screen=name, token=tok):
                    self.assertIsInstance(tok, str)
                    self.assertTrue(tok.strip(), f"Empty token in {name}")


class TestScreenMatchDataclass(unittest.TestCase):
    def test_default_matched_tokens_is_empty_list(self):
        m = ScreenMatch(screen="test", confidence=1.0, category="main")
        self.assertEqual(m.matched_tokens, [])

    def test_fields_accessible(self):
        m = ScreenMatch(
            screen="welcome",
            confidence=0.75,
            category="wizard",
            matched_tokens=["tok1"],
        )
        self.assertEqual(m.screen, "welcome")
        self.assertAlmostEqual(m.confidence, 0.75)
        self.assertEqual(m.category, "wizard")
        self.assertEqual(m.matched_tokens, ["tok1"])


if __name__ == "__main__":
    unittest.main()
