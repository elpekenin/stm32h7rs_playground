"""Define common logic."""

from __future__ import annotations

import abc
import typing as t


class UnknownDependencyError(Exception):
    """Custom error class."""


class Dependency(abc.ABC):
    """Root node for the hierarchy tree of dependency sources."""

    pinned_to: str
    """Which version is currently targeted."""

    latest: str
    """Latest version found."""

    @classmethod
    @abc.abstractmethod
    def matches(cls, url: str) -> bool:
        """Whether the input URL matches this dependency's pattern."""

    @classmethod
    @abc.abstractmethod
    def new(cls, url: str) -> t.Self:
        """Create an instance of the class given an URL that matches."""

    @abc.abstractmethod
    def url_for(self, version: str) -> str:
        """Generate an URL to target the specified version."""

    @abc.abstractmethod
    def show(self) -> str:
        """How to show this dependency to the user."""

    @t.final
    @classmethod
    def from_url(cls, url: str) -> Dependency:
        for subcls in cls.__subclasses__():
            if subcls.matches(url):
                return subcls.new(url)

        msg = f"Can not identify '{url}'. It might not be implemented yet"
        raise UnknownDependencyError(msg)
