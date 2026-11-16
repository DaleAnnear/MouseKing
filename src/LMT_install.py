#!/usr/bin/env python3
"""Prepare the Docker images and example input list for MouseKing.

The local mode builds images from the Dockerfiles under <globdir>/src.
Use the --dockerfile-* options to select different Dockerfiles. The online
mode pulls the corresponding image tags from Docker Hub.
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
    # Only the optional GitHub release check needs requests.
    requests = None


# Command and version helpers

def run(cmd: Sequence[str], *, cwd: Optional[Path] = None) -> None:
    """Run a command with live output and raise if it exits unsuccessfully."""
    print(f"\n$ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=True)

def which_or_die(tool: str, install_url: str) -> None:
    if shutil.which(tool) is None:
        print(f"❌ {tool} is not installed or not on PATH.")
        print(f"👉 Install instructions: {install_url}")
        sys.exit(1)

def parse_docker_version(output: str) -> str:
    """Extract the version number from the Docker CLI banner."""
    parts = output.replace(",", "").split()
    if "version" in parts:
        i = parts.index("version")
        if i + 1 < len(parts):
            return parts[i + 1]
    return output.strip()

def parse_nextflow_version(output: str) -> str:
    """Extract the first dotted version number from the Nextflow banner.

    Some versions print a separate build number after the release version.
    """
    m = re.search(r'(\d+\.\d+(?:\.\d+)*)', output)
    return m.group(1) if m else output.strip()

def version_tuple(v: str) -> Tuple[int, ...]:
    """Read the leading numeric components for a numeric version comparison."""
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
    """Require a tool on PATH and report its version when available.

    The GitHub comparison is advisory. The installer can proceed when the local
    version probe or the remote release lookup fails.
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
    """Temporarily change directories and restore the caller's directory on exit."""
    prev = Path.cwd()
    os.chdir(new_dir)
    try:
        yield
    finally:
        os.chdir(prev)


# Example inputs and Docker images

def write_example_input(glob_dir: Path) -> None:
    """Regenerate Example/data/input.txt with paths to the three bundled databases."""
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
    """Build an image with COPY sources resolved from the supplied context."""
    dockerfile = dockerfile.resolve()
    context_dir = context_dir.resolve()

    if not dockerfile.exists():
        raise FileNotFoundError(f"Dockerfile not found: {dockerfile}")
    if not context_dir.exists():
        raise FileNotFoundError(f"Context dir not found: {context_dir}")

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

    write_example_input(glob_dir)

    # The workflow defaults use these stage names and version suffixes.
    img_rebuild = f"{args.repo}:lmt_rebuild-{args.version}"
    img_process = f"{args.repo}:lmt_processing-{args.version}"
    img_pca     = f"{args.repo}:lmt_pca-{args.version}"

    docker_dir = glob_dir / "src"
    df_rebuild = Path(args.dockerfile_rebuild) if args.dockerfile_rebuild else (docker_dir / "Dockerfile.rebuild")
    df_process = Path(args.dockerfile_processing) if args.dockerfile_processing else (docker_dir / "Dockerfile.processing")
    df_pca     = Path(args.dockerfile_pca) if args.dockerfile_pca else (docker_dir / "Dockerfile.pca")

    if args.mode == "local":
        print("🔧 Running LOCAL Docker install (build).")

        # Dockerfile overrides still build from src, where the scripts and environments live.
        context_dir = docker_dir

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
