#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
"""Behaviour tests for skills/enterprise-readiness/scripts/submit-badges.py.

The tests replace the HTTP opener with a fake, so no request reaches
bestpractices.dev. Usage: python3 tests/test_submit_badges.py
"""

import contextlib
import importlib.util
import io
import os
import pathlib
import sys
import tempfile
import unittest
import urllib.parse
from unittest import mock

SCRIPT = (
    pathlib.Path(__file__).resolve().parent.parent
    / "skills/enterprise-readiness/scripts/submit-badges.py"
)
# Loading the script must not leave a __pycache__ directory among the shipped
# scripts.
sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("submit_badges", SCRIPT)
sb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sb)

EDIT_PAGE = """
<meta name="csrf-token" content="csrf-abc">
<form>
<input type="hidden" name="authenticity_token" value="auth-123">
<input type="hidden" name="project[lock_version]" value="7">
<img id="crypto_tls12_enough" alt="Not enough">
<img id="tests_are_added_enough" alt="Enough">
</form>
"""


class FakeResponse:
    def __init__(self, code, body=""):
        self.code = code
        self.body = body.encode("utf-8")

    def getcode(self):
        return self.code

    def read(self):
        return self.body


class FakeOpener:
    """Records requests and answers with queued responses."""

    def __init__(self, *responses):
        self.responses = list(responses)
        self.requests = []

    def open(self, req):
        self.requests.append(req)
        return self.responses.pop(0)


class PatternTests(unittest.TestCase):
    def test_lock_version_name_before_value(self):
        m = sb.LOCK_VERSION_PATTERN.search(
            '<input name="project[lock_version]" type="hidden" value="12">'
        )
        self.assertEqual(m.group(1) or m.group(2), "12")

    def test_lock_version_value_before_name(self):
        m = sb.LOCK_VERSION_PATTERN.search(
            '<input value="34" type="hidden" name="project[lock_version]">'
        )
        self.assertEqual(m.group(1) or m.group(2), "34")


class EditPageTests(unittest.TestCase):
    def test_tokens_and_lock_version_are_extracted(self):
        opener = FakeOpener(FakeResponse(200, EDIT_PAGE))
        self.assertEqual(
            sb.get_edit_page(opener, 42, "silver"), ("auth-123", "csrf-abc", "7")
        )
        self.assertEqual(
            opener.requests[0].full_url,
            "https://www.bestpractices.dev/en/projects/42/silver/edit",
        )

    def test_redirect_means_expired_cookie(self):
        opener = FakeOpener(FakeResponse(302))
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(sb.get_edit_page(opener, 42), (None, None, None))
        self.assertIn("cookie may be expired", out.getvalue())

    def test_insufficient_criteria_are_listed(self):
        opener = FakeOpener(FakeResponse(200, EDIT_PAGE))
        self.assertEqual(
            sb.check_insufficient_criteria(opener, 42),
            [("crypto_tls12", "Not enough")],
        )


class SubmitTests(unittest.TestCase):
    def submit(self, response, data):
        opener = FakeOpener(response)
        with contextlib.redirect_stdout(io.StringIO()):
            ok = sb.submit_data(opener, 42, "passing", data, "auth-123", "7")
        form = urllib.parse.parse_qs(opener.requests[0].data.decode("utf-8"))
        return ok, form, opener.requests[0]

    def test_redirect_is_success_and_form_is_encoded(self):
        ok, form, req = self.submit(
            FakeResponse(302),
            {"tests_are_added_status": "Met", "homepage_url_status": "Met"},
        )
        self.assertTrue(ok)
        self.assertEqual(
            req.full_url, "https://www.bestpractices.dev/en/projects/42/passing"
        )
        self.assertEqual(form["_method"], ["patch"])
        self.assertEqual(form["authenticity_token"], ["auth-123"])
        self.assertEqual(form["project[lock_version]"], ["7"])
        self.assertEqual(form["project[tests_are_added_status]"], ["Met"])

    def test_auto_detected_fields_are_not_sent(self):
        _ok, form, _req = self.submit(FakeResponse(302), {"homepage_url_status": "Met"})
        self.assertNotIn("project[homepage_url_status]", form)

    def test_form_errors_are_failure(self):
        body = (
            "<p>The form contains 1 error</p><ul><li>Justification required</li></ul>"
        )
        ok, _form, _req = self.submit(FakeResponse(200, body), {"x_status": "Met"})
        self.assertFalse(ok)

    def test_unexpected_status_is_failure(self):
        ok, _form, _req = self.submit(FakeResponse(500), {"x_status": "Met"})
        self.assertFalse(ok)


class OpenerTests(unittest.TestCase):
    def test_session_cookie_is_https_only_for_bestpractices(self):
        _opener, jar = sb.make_opener("cookie-value")
        (cookie,) = list(jar)
        self.assertEqual(cookie.name, "_BadgeApp_session")
        self.assertEqual(cookie.domain, "www.bestpractices.dev")
        self.assertTrue(cookie.secure)


class MainTests(unittest.TestCase):
    def run_main(self, argv, env):
        with (
            mock.patch.object(sb.sys, "argv", ["submit-badges.py", *argv]),
            mock.patch.dict(os.environ, env, clear=True),
            contextlib.redirect_stdout(io.StringIO()) as out,
            self.assertRaises(SystemExit) as exit_info,
        ):
            sb.main()
        return exit_info.exception.code, out.getvalue()

    def test_missing_cookie_exits_1(self):
        with tempfile.TemporaryDirectory() as home:
            code, out = self.run_main(["42"], {"HOME": home})
        self.assertEqual(code, 1)
        self.assertIn("Set BADGE_COOKIE", out)

    def test_cookie_file_with_open_permissions_warns(self):
        with tempfile.TemporaryDirectory() as home:
            path = pathlib.Path(home, ".badge-cookie.txt")
            path.write_text("")
            path.chmod(0o644)
            _code, out = self.run_main(["42"], {"HOME": home})
        self.assertIn("expected 0o600", out)

    def test_no_arguments_prints_usage(self):
        code, out = self.run_main([], {"BADGE_COOKIE": "x"})
        self.assertEqual(code, 1)
        self.assertIn("Usage:", out)


if __name__ == "__main__":
    unittest.main()
