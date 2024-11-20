"""Check if dependencies are up to date."""

# TODO(elpekenin): Move to dedicated repo (?)

from __future__ import annotations

import argparse
import logging
from pathlib import Path

import dependencies as d

NAME = Path(__file__).parent.name
logger = logging.getLogger(NAME)


def directory(raw: str) -> Path:
    """Parse a directory argument."""
    path = Path(raw)
    if path.is_dir():
        return path

    msg = f"'{raw}' is not a directory."
    raise argparse.ArgumentTypeError(msg)


def up_to_date(dependency: d.Dependency) -> bool:
    """Check if dependency is pinned to its latest version."""
    pinned = dependency.pinned_to
    latest = dependency.latest

    up_to_date = pinned == latest

    if up_to_date:
        logger.info("%s up to date.", dependency.show())
    else:
        logger.error(
            "%s is not up to date. Latest version is '%s', but it is pinned to '%s'.",
            dependency.show(),
            latest,
            dependency.pinned_to,
        )

    return up_to_date


def main() -> int:
    """Entrypoint of the tool."""
    logging.basicConfig(
        level=logging.INFO,
        format="[%(levelname)s] %(name)s: %(message)s",
    )

    parser = argparse.ArgumentParser(
        prog=NAME,
        description=__doc__,
    )

    parser.add_argument(
        "root",
        help="root directory of the project (where build.zig lives)",
        type=directory,
    )

    parser.add_argument(
        "-r",
        "--recursive",
        help="whether to scan subdirectories for other .zon files",
        action="store_true",
    )

    parser.add_argument(
        "-u",
        "--update",
        help="whether to update dependencies to their latest version",
        action="store_true",
    )

    args = parser.parse_args()

    dependencies = d.find_all(args.root, recursive=args.recursive)

    for dependency in dependencies:
        ok = up_to_date(dependency)
        if not ok and args.update:
            new_url = dependency.url_for(dependency.latest)
            logging.warning("%s", new_url)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
