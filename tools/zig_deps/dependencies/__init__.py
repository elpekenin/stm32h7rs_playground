"""Various sources from which URL dependencies might come.

GitHub releases or commits, tarballs from anywhere, etc.
"""

from __future__ import annotations

import re
import typing as t

from ._base import Dependency
from ._github import Commit

if t.TYPE_CHECKING:
    from collections.abc import Generator
    from pathlib import Path

ZON = "build.zig.zon"
ZON_URL_PATTERN = re.compile(r"\s*\.url\s*=\s*(?P<url>.*)")

__all__ = (
    "Dependency",
    "Commit",
    "find_all",
)


def _find_zons(root: Path, *, recursive: bool) -> Generator[Path]:
    """Find all build.zig.zon files on the source code."""
    if recursive:
        yield from root.glob(f"**/{ZON}")
    else:
        zon = root / ZON
        if not zon.exists():
            msg = f"{ZON} not found"
            raise ValueError(msg)

        yield zon


def find_all(root: Path, *, recursive: bool) -> list[Dependency]:
    """Find all dependencies (referenced by URL) on the source code."""
    deps = []

    for zon in _find_zons(root, recursive=recursive):
        with zon.open(encoding="utf8") as f:
            for line in f.readlines():
                matches = ZON_URL_PATTERN.match(line)
                if matches is None:
                    continue

                url = t.cast(str, matches.groups(0)[0]).replace('"', "")
                deps.append(
                    Dependency.from_url(url),
                )

    return deps
