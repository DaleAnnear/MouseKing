#!/usr/bin/env python3
"""
LMT installer (Docker-first)

Modes:
  - local  : build Docker images from Dockerfiles
  - online : pull prebuilt Docker images from Docker Hub

Expected Dockerfiles (default):
  <globdir>/MouseKing/src/Dockerfile.rebuild
  <globdir>/MouseKing/src/Dockerfile.processing
  <globdir>/MouseKing/src/Dockerfile.pca

You can also pass custom paths with --dockerfile-*.
"""

from __future__ import annotations

import argparse
import importlib
import os
import shutil
import subprocess
import sys
import re
from contextlib import contextmanager
from pathlib import Path
from typing import Optional, Sequence, Tuple

try:
    import requests
except ImportError:
    requests = None  # we'll degrade gracefully


# -----------------------------
# Utility helpers
# -----------------------------

def run(cmd: Sequence[str], *, cwd: Optional[Path] = None) -> None:
    """Run a command and stream output; raise on failure."""
    print(f"\n$ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=True)

def which_or_die(tool: str, install_url: str) -> None:
    if shutil.which(tool) is None:
        print(f"❌ {tool} is not installed or not on PATH.")
        print(f"👉 Install instructions: {install_url}")
        sys.exit(1)

def parse_docker_version(output: str) -> str:
    # e.g. "Docker version 26.1.4, build 5650f9b"
    parts = output.replace(",", "").split()
    # find the token after "version"
    if "version" in parts:
        i = parts.index("version")
        if i + 1 < len(parts):
            return parts[i + 1]
    return output.strip()

def parse_nextflow_version(output: str) -> str:
    """
    Extract a semantic version from nextflow output.
    Handles lines like:
      - "nextflow version 25.10.4 build 12345"
      - "Nextflow version 25.10.4"
      - "nextflow 25.10.4"
    """
    m = re.search(r'(\d+\.\d+(?:\.\d+)*)', output)
    return m.group(1) if m else output.strip()

def version_tuple(v: str) -> Tuple[int, ...]:
    out = []
    for x in v.split("."):
        try:
            out.append(int(x))
        except ValueError:
            break
    return tuple(out)

def check_tool(tool_name: str,
               version_cmd: Sequence[str],
               parse_version_fn,
               github_repo: Optional[str],
               install_url: str) -> None:
    """
    Check that a tool exists and print local version.
    Optionally compare to latest GitHub release (if requests is available).
    """
    which_or_die(tool_name, install_url)

    try:
        result = subprocess.run(version_cmd, capture_output=True, text=True, check=True)
        local_version = parse_version_fn((result.stdout or result.stderr).strip())
    except Exception as e:
        print(f"⚠️ Could not determine {tool_name} version: {e}")
        return

    print(f"✅ Found {tool_name} version {local_version}")

    if not github_repo:
        return

    if requests is None:
        print(f"ℹ️ 'requests' not installed; skipping latest {tool_name} version check.")
        return

    try:
        url = f"https://api.github.com/repos/{github_repo}/releases/latest"
        resp = requests.get(
            url,
            timeout=10,
            headers={"Accept": "application/vnd.github+json", "User-Agent": "LMT_install"})
        resp.raise_for_status()
        latest_version = resp.json()["tag_name"].lstrip("v")
    except Exception:
        print(f"⚠️ Could not fetch latest {tool_name} version (GitHub API issue). Continuing.\n")
        return

    if version_tuple(local_version) < version_tuple(latest_version):
        print(f"⚠️ Your {tool_name} version ({local_version}) is older than latest ({latest_version}).")
        print(f"👉 Update instructions: {install_url}\n")
    else:
        print(f"👍 {tool_name} is up to date ({local_version}).\n")

@contextmanager
def pushd(new_dir: Path):
    prev = Path.cwd()
    os.chdir(new_dir)
    try:
        yield
    finally:
        os.chdir(prev)


# -----------------------------
# Installer logic
# -----------------------------

def write_example_input(glob_dir: Path) -> None:
    example_dir = glob_dir / "Example" / "data"
    example_dir.mkdir(parents=True, exist_ok=True)

    lines = [
        str(example_dir / "1765-24.sqlite"),
        str(example_dir / "1766-24.sqlite"),
        str(example_dir / "1767-24.sqlite"),
    ]
    def_example_file = example_dir / "input.txt"
    with def_example_file.open("w", encoding="utf-8", newline="") as f:
        for path in lines:
            f.write(f"{path}\n")
    print(f"✅ Wrote example input list: {def_example_file}")

def docker_build_image(tag: str, dockerfile: Path, context_dir: Path) -> None:
    dockerfile = dockerfile.resolve()
    context_dir = context_dir.resolve()

    if not dockerfile.exists():
        raise FileNotFoundError(f"Dockerfile not found: {dockerfile}")
    if not context_dir.exists():
        raise FileNotFoundError(f"Context dir not found: {context_dir}")

    # Build context is fixed to /home/dannear/LMT/MouseKing/src
    run(["docker", "build", "-f", str(dockerfile), "-t", tag, str(context_dir)])

def docker_pull_image(tag: str) -> None:
    run(["docker", "pull", tag])

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("globdir", help="Pipeline install directory")
    ap.add_argument("--mode", choices=["local", "online"], default="local",
                    help="local=build images, online=pull images")
    ap.add_argument("--repo", default="daleannear/mouseking",
                    help="Docker Hub repo (default: daleannear/mouseking)")
    ap.add_argument("--version", default="1.0",
                    help="Version tag suffix for images (default: 1.0)")

    # Default Dockerfiles
    ap.add_argument("--dockerfile-rebuild", default=None,
                    help="Path to rebuild Dockerfile (optional)")
    ap.add_argument("--dockerfile-processing", default=None,
                    help="Path to processing Dockerfile (optional)")
    ap.add_argument("--dockerfile-pca", default=None,
                    help="Path to PCA Dockerfile (optional)")

    args = ap.parse_args()
    glob_dir = Path(args.globdir).expanduser().resolve()

    print(f"INSTALL DIRECTORY: {glob_dir}")
    if not glob_dir.exists():
        print(f"❌ globdir does not exist: {glob_dir}")
        sys.exit(1)

    # Check Docker + Nextflow
    check_tool(
        tool_name="docker",
        version_cmd=["docker", "--version"],
        parse_version_fn=parse_docker_version,
        github_repo="docker/cli",
        install_url="https://docs.docker.com/engine/install/"
    )
    check_tool(
        tool_name="nextflow",
        version_cmd=["nextflow", "-version"],
        parse_version_fn=parse_nextflow_version,
        github_repo="nextflow-io/nextflow",
        install_url="https://www.nextflow.io/docs/latest/getstarted.html"
    )

    # Example input file
    write_example_input(glob_dir)

    # Image tags (what you push/pull)
    # You can change naming scheme here if you prefer.
    img_rebuild = f"{args.repo}:lmt_rebuild-{args.version}"
    img_process = f"{args.repo}:lmt_processing-{args.version}"
    img_pca     = f"{args.repo}:lmt_pca-{args.version}"

    # Dockerfile locations
    docker_dir = glob_dir / "src"
    df_rebuild = Path(args.dockerfile_rebuild) if args.dockerfile_rebuild else (docker_dir / "Dockerfile.rebuild")
    df_process = Path(args.dockerfile_processing) if args.dockerfile_processing else (docker_dir / "Dockerfile.processing")
    df_pca     = Path(args.dockerfile_pca) if args.dockerfile_pca else (docker_dir / "Dockerfile.pca")

    if args.mode == "local":
        print("🔧 Running LOCAL Docker install (build).")

        # Build context: use glob_dir so COPY lines can see the repo files.
        context_dir = docker_dir

        # Build images
        docker_build_image(img_rebuild, df_rebuild, context_dir)
        docker_build_image(img_process, df_process, context_dir)
        docker_build_image(img_pca, df_pca, context_dir)

        print("\n✅ Built Docker images:")
        print(f"  - {img_rebuild}")
        print(f"  - {img_process}")
        print(f"  - {img_pca}")

    elif args.mode == "online":
        print("🌐 Running ONLINE Docker install (pull).")
        docker_pull_image(img_rebuild)
        docker_pull_image(img_process)
        docker_pull_image(img_pca)

        print("\n✅ Pulled Docker images:")
        print(f"  - {img_rebuild}")
        print(f"  - {img_process}")
        print(f"  - {img_pca}")

    else:
        raise ValueError(f"Unexpected mode: {args.mode}")

if __name__ == "__main__":
    main()