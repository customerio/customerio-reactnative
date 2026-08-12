#!/usr/bin/env python3
"""Verify or byte-copy the pinned MBL-2232 lifecycle contract bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import subprocess
import sys
import tempfile
from typing import Any


SCHEMA = "cio-lifecycle-contract-lock/1"
SOURCE_REPOSITORY = "customerio/customerio-ios"
SOURCE_COMMIT = "342eabf17ea7eef258c256ff2138279bfa15bc9a"
ALGORITHM = "sha256"
EXPECTED_PATHS = (
    "docs/dev-notes/IOS27-LIFECYCLE-CALLBACK-CONTRACT.md",
    "docs/dev-notes/IOS27-LIFECYCLE-TRACE-V1.md",
    "docs/dev-notes/ios27-lifecycle-capture-manifest-v1.schema.json",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/aggregate.invalid-counts.json",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/completion.invalid-drop-without-full-buffer.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/completion.valid-diagnostic-drop.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/completion.valid-zero-call.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/manifest.completion-valid.json",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/manifest.diagnostic-drop-valid.json",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/manifest.valid.json",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/native.invalid-aggregate-zero.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/native.valid.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/wrapper.invalid-aggregate-zero.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/wrapper.invalid-handoff-classification.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1-test-vectors/wrapper.valid.ndjson",
    "docs/dev-notes/ios27-lifecycle-trace-v1.schema.json",
    "docs/dev-notes/test_validate_ios27_lifecycle_trace.py",
    "docs/dev-notes/validate_ios27_lifecycle_trace.py",
)
LOCK_RELATIVE_PATH = Path("docs/dev-notes/ios27-lifecycle-contract-v1.lock.json")
ACCEPTED_ORIGINS = {
    "https://github.com/customerio/customerio-ios",
    "https://github.com/customerio/customerio-ios.git",
    "git@github.com:customerio/customerio-ios.git",
}


class ContractError(RuntimeError):
    pass


def _load_lock(path: Path) -> list[dict[str, str]]:
    if path.is_symlink() or not path.is_file():
        raise ContractError(f"lock must be a regular non-symlink file: {path}")
    try:
        payload: Any = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ContractError(f"cannot read lock {path}: {error}") from error
    if not isinstance(payload, dict) or set(payload) != {
        "schema", "source_repository", "source_commit", "algorithm", "files"
    }:
        raise ContractError("lock has an unexpected top-level shape")
    expected_scalars = {
        "schema": SCHEMA,
        "source_repository": SOURCE_REPOSITORY,
        "source_commit": SOURCE_COMMIT,
        "algorithm": ALGORITHM,
    }
    for key, expected in expected_scalars.items():
        if payload.get(key) != expected:
            raise ContractError(f"lock {key} must equal {expected}")
    files = payload.get("files")
    if not isinstance(files, list) or len(files) != len(EXPECTED_PATHS):
        raise ContractError(f"lock must contain exactly {len(EXPECTED_PATHS)} files")
    normalized: list[dict[str, str]] = []
    seen: set[str] = set()
    for index, item in enumerate(files):
        if not isinstance(item, dict) or set(item) != {"path", "sha256"}:
            raise ContractError(f"lock file entry {index} has an unexpected shape")
        relative = item.get("path")
        digest = item.get("sha256")
        if not isinstance(relative, str) or not isinstance(digest, str):
            raise ContractError(f"lock file entry {index} must contain strings")
        if relative in seen:
            raise ContractError(f"duplicate lock path: {relative}")
        seen.add(relative)
        _validate_relative_path(relative)
        if len(digest) != 64 or any(character not in "0123456789abcdef" for character in digest):
            raise ContractError(f"invalid sha256 for {relative}")
        normalized.append({"path": relative, "sha256": digest})
    if tuple(item["path"] for item in normalized) != EXPECTED_PATHS:
        raise ContractError("lock paths or ordering differ from the canonical 18-file bundle")
    return normalized


def _validate_relative_path(value: str) -> None:
    path = PurePosixPath(value)
    if path.is_absolute() or not path.parts or ".." in path.parts or "." in path.parts:
        raise ContractError(f"unsafe repo-relative path: {value}")
    if str(path) != value or path.parts[0] != "docs":
        raise ContractError(f"non-canonical bundle path: {value}")


def _root(path: str) -> Path:
    root = Path(path)
    if root.is_symlink() or not root.is_dir():
        raise ContractError(f"root must be an existing non-symlink directory: {root}")
    return root.resolve()


def _target(root: Path, relative: str, *, must_exist: bool) -> Path:
    candidate = root.joinpath(*PurePosixPath(relative).parts)
    current = root
    for part in PurePosixPath(relative).parts:
        current = current / part
        if current.is_symlink():
            raise ContractError(f"symlink is forbidden in bundle path: {relative}")
    resolved = candidate.resolve(strict=False)
    if resolved != root and root not in resolved.parents:
        raise ContractError(f"bundle path escapes root: {relative}")
    if must_exist and (not candidate.is_file() or candidate.is_symlink()):
        raise ContractError(f"missing or non-regular bundle file: {relative}")
    return candidate


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify(root: Path, entries: list[dict[str, str]]) -> None:
    for entry in entries:
        path = _target(root, entry["path"], must_exist=True)
        actual = _sha256(path)
        if actual != entry["sha256"]:
            raise ContractError(
                f"sha256 mismatch for {entry['path']}: expected {entry['sha256']}, got {actual}"
            )


def _git(root: Path, *arguments: str) -> str:
    try:
        completed = subprocess.run(
            ["git", "-C", str(root), *arguments],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        raise ContractError(f"git {' '.join(arguments)} failed for {root}") from error
    return completed.stdout.strip()


def _verify_source_checkout(root: Path, entries: list[dict[str, str]]) -> None:
    if _git(root, "rev-parse", "--show-toplevel") != str(root):
        raise ContractError("source-root must be the Git checkout root")
    if _git(root, "rev-parse", "HEAD") != SOURCE_COMMIT:
        raise ContractError(f"source HEAD must equal {SOURCE_COMMIT}")
    if _git(root, "remote", "get-url", "origin") not in ACCEPTED_ORIGINS:
        raise ContractError(f"source origin must identify {SOURCE_REPOSITORY}")
    verify(root, entries)


def _atomic_copy(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(dir=destination.parent, prefix=".ios27-contract-", delete=False) as stream:
            temporary_name = stream.name
            with source.open("rb") as source_stream:
                for chunk in iter(lambda: source_stream.read(1024 * 1024), b""):
                    stream.write(chunk)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary_name, destination)
        temporary_name = None
    finally:
        if temporary_name is not None:
            try:
                Path(temporary_name).unlink()
            except FileNotFoundError:
                pass


def sync(source_root: Path, destination_root: Path, entries: list[dict[str, str]]) -> None:
    _verify_source_checkout(source_root, entries)
    for entry in entries:
        source = _target(source_root, entry["path"], must_exist=True)
        destination = _target(destination_root, entry["path"], must_exist=False)
        if destination.exists() and (destination.is_symlink() or not destination.is_file()):
            raise ContractError(f"destination is not a regular file: {entry['path']}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination = _target(destination_root, entry["path"], must_exist=False)
        _atomic_copy(source, destination)
    verify(destination_root, entries)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lock", help="lock path (defaults to the lock beside this repository script)")
    subparsers = parser.add_subparsers(dest="command", required=True)
    verify_parser = subparsers.add_parser("verify", help="verify a vendored bundle")
    verify_parser.add_argument("--root", required=True)
    sync_parser = subparsers.add_parser("sync", help="copy the verified pinned source bundle")
    sync_parser.add_argument("--source-root", required=True)
    sync_parser.add_argument("--destination-root", required=True)
    return parser


def main() -> int:
    arguments = _parser().parse_args()
    default_root = Path(__file__).resolve().parents[1]
    lock_path = Path(arguments.lock) if arguments.lock else default_root / LOCK_RELATIVE_PATH
    try:
        entries = _load_lock(lock_path)
        if arguments.command == "verify":
            root = _root(arguments.root)
            verify(root, entries)
            print(f"verified {len(entries)} canonical files under {root}")
        else:
            source_root = _root(arguments.source_root)
            destination_root = _root(arguments.destination_root)
            sync(source_root, destination_root, entries)
            print(f"synced and verified {len(entries)} canonical files under {destination_root}")
    except ContractError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
