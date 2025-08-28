#!/usr/bin/env python3

import argparse, sys, os, shutil, subprocess, sys, importlib, shlex #requests 
from pathlib import Path
from contextlib import contextmanager

p = argparse.ArgumentParser()
p.add_argument("globdir")
p.add_argument("--mode", choices=["local", "online"], default="local")
args = p.parse_args()

def check_tool(tool_name, version_cmd, parse_version_fn, github_repo, install_url):
    """
    Generic checker for a CLI tool.
    """
    tool_path = shutil.which(tool_name)
    if tool_path is None:
        print(f"❌ {tool_name} is not installed on this system.\n")
        print(f"👉 To install {tool_name}, follow instructions here:")
        print(f"   {install_url}\n")
        sys.exit(1)

    # Get local version
    try:
        result = subprocess.run(version_cmd, capture_output=True, text=True, check=True)
        local_version = parse_version_fn(result.stdout.strip())
    except Exception as e:
        print(f"⚠️ Could not determine {tool_name} version: {e}")
        return

    print(f"✅ Found {tool_name} version {local_version}")

    # Get latest release
    try:
        url = f"https://api.github.com/repos/{github_repo}/releases/latest"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        latest_version = resp.json()["tag_name"].lstrip("v")
    except Exception:
        print(f"⚠️ Could not fetch latest {tool_name} version (GitHub API issue).")
        print("   Continuing with installed version.\n")
        return

    # Compare versions
    def version_tuple(v): return tuple(int(x) for x in v.split(".") if x.isdigit())
    if version_tuple(local_version) < version_tuple(latest_version):
        print(f"⚠️ Your {tool_name} version ({local_version}) is older than the latest ({latest_version}).")
        print(f"👉 Update instructions: {install_url}")
        print("   Continuing anyway...\n")
    else:
        print(f"👍 {tool_name} is up to date ({local_version}).\n")

def parse_apptainer_version(output):
    # e.g. "apptainer version 1.3.2"
    return output.split()[-1]

def parse_nextflow_version(output):
    # e.g. "nextflow version 23.10.1.5843"
    return output.split()[2].split(".")[0:3]  # strip build number
    # returns like ['23','10','1']

@contextmanager
def pushd(new_dir):
    prev = Path.cwd()
    os.chdir(new_dir)
    try:
        yield
    finally:
        os.chdir(prev)

def main():
    glob_dir = args.globdir
    print(f"INSTALL DIRECTORY: {glob_dir}")
    #glob_dir = sys.argv[1]
    
    # Check Apptainer
    check_tool(
        tool_name="apptainer",
        version_cmd=["apptainer", "--version"],
        parse_version_fn=parse_apptainer_version,
        github_repo="apptainer/apptainer",
        install_url="https://apptainer.org/docs/admin/main/installation.html"
    )

    # Check Nextflow
    check_tool(
        tool_name="nextflow",
        version_cmd=["nextflow", "-version"],
        parse_version_fn=lambda out: out.split()[2].split("-")[0].lstrip("v"),
        github_repo="nextflow-io/nextflow",
        install_url="https://www.nextflow.io/docs/latest/getstarted.html"
    )

    # Continue with rest of pipeline
    print("🚀 Running rest of the script...")

    lines = [f"{glob_dir}/Example/data/1765-24.sqlite",
        f"{glob_dir}/Example/data/1766-24.sqlite",
        f"{glob_dir}/Example/data/1767-24.sqlite",]
    def_example_file = f"{glob_dir}/Example/data/input.txt"
    with open(def_example_file, "w", encoding="utf-8", newline="") as f:
        for path in lines:
            f.write(f"{path}\n")

    if args.mode == "local":
        print("Running local install...")
        sys.path.append(os.path.abspath(glob_dir))
        module1 = importlib.import_module("scripts.def_files.rebuild_def_content")
        def_rebuild_file_content = module1.def_rebuild_file_content
        module2 = importlib.import_module("scripts.def_files.process_def_content")
        def_process_file_content = module2.def_process_file_content
        module3 = importlib.import_module("scripts.def_files.PCA_def_content")
        def_pca_file_content = module3.def_pca_file_content

        # Save to a file
        def_rebuild_filename = f"{glob_dir}/Apptainer/1_LMT_rebuild.def"
        with open(def_rebuild_filename, "w") as file:
            file.write(def_rebuild_file_content)

        def_process_filename = f"{glob_dir}/Apptainer/2_LMT_processing.def"
        with open(def_process_filename, "w") as file:
            file.write(def_process_file_content)

        def_pca_filename = f"{glob_dir}/Apptainer/3_LMT_pca.def"
        with open(def_pca_filename, "w") as file:
            file.write(def_pca_file_content)    

        # Install apptainer images from def files
        with pushd(f"{glob_dir}/Apptainer/"):
            os.system("apptainer build 1_LMT_rebuild.sif 1_LMT_rebuild.def")

        with pushd(f"{glob_dir}/Apptainer/"):
            os.system("apptainer build 2_LMT_processing.sif 2_LMT_processing.def")

        with pushd(f"{glob_dir}/Apptainer/"):
            os.system("apptainer build 3_LMT_pca.sif 3_LMT_pca.def")

    elif args.mode == "online":
        print("Running online install...") 
        # Install apptainer images from cloud.sylabs.io
        os.system(f"apptainer build {glob_dir}/Apptainer/1_LMT_rebuild.sif library://daleannear/mouseking/lmtrebuild")
        os.system(f"apptainer build {glob_dir}/Apptainer/2_LMT_processing.sif library://daleannear/mouseking/lmtprocess")
        os.system(f"apptainer build {glob_dir}/Apptainer/3_LMT_pca.sif library://daleannear/mouseking/lmtpca")
    
    else:
    # this should never happen, since argparse restricts choices
        raise ValueError(f"Unexpected mode: {args.mode}")

if __name__ == "__main__":
    main()