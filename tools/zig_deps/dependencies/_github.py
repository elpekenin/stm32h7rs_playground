"""GitHub-based dependencies."""

# TODO(elpekenin): Authentication, for rate limiter

from __future__ import annotations

import re
import typing as t

import requests

from ._base import Dependency


class RateLimitError(Exception):
    """Custom class to display error."""


def request_following_redirect(url: str) -> dict:
    """If request yields a redirection, follow it."""
    response = requests.get(url, timeout=5)
    json = response.json()

    while True:
        if "message" in json and "API rate limit" in json["message"]:
            raise RateLimitError

        if "url" not in json:
            break

        json = request_following_redirect(json["url"])

    return json


class Commit(Dependency):
    """Commit-targetted repository."""

    URL_PATTERN = re.compile(
        r"(?:git|git\+https|https)://github.com/(?P<owner>.*)/(?P<repo>.*)#(?P<commit>.*),",
    )
    COMMIT_URL = "https://github.com/{owner}/{repo}#{commit}"
    LATEST_COMMIT_API_URL = "https://api.github.com/repos/{owner}/{repo}/commits"

    def __init__(
        self,
        owner: str,
        repo: str,
        commit: str,
        latest: str,
    ) -> None:
        self.owner = owner
        self.repo = repo

        self.pinned_to = commit
        self.latest = latest

    @classmethod
    def _parse(cls, url: str) -> tuple[str, str, str] | None:
        """Extract repo, owner, commit from URL, or None if doesn't match."""
        found = cls.URL_PATTERN.match(url)
        if found is None:
            return found

        return t.cast(tuple[str, str, str], found.groups(0))

    @classmethod
    def _find_latest(cls, owner: str, repo: str) -> str:
        url = cls.LATEST_COMMIT_API_URL.format(
            owner=owner,
            repo=repo,
        )

        json = request_following_redirect(url)

        latest_commit = json[0]
        return latest_commit["sha"]

    @classmethod
    def matches(cls, url: str) -> bool:
        parsed = cls._parse(url)
        return parsed is not None

    @classmethod
    def new(cls, url: str) -> t.Self:
        parsed = cls._parse(url)
        if parsed is None:
            raise RuntimeError

        owner, repo, commit = parsed
        return cls(
            owner,
            repo,
            commit,
            cls._find_latest(owner, repo),
        )

    def url_for(self, version: str) -> str:
        return self.COMMIT_URL.format(
            owner=self.owner,
            repo=self.repo,
            commit=version,
        )

    def show(self) -> str:
        return f"{self.owner}/{self.repo}"
