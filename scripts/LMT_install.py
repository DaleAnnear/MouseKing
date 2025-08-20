#!/usr/bin/env python3

import sys, os, shutil, subprocess, sys, requests, importlib, shlex
from pathlib import Path
from contextlib import contextmanager

def get_local_version():
    """Return installed Apptainer version or None if not installed."""
    apptainer_path = shutil.which("apptainer")
    if apptainer_path is None:
        return None
    try:
        result = subprocess.run(
            ["apptainer", "--version"],
            capture_output=True, text=True, check=True
        )
        # Output looks like: "apptainer version 1.3.2"
        return result.stdout.strip().split()[-1]
    except Exception:
        return None

def get_latest_version():
    """Fetch latest release version from Apptainer GitHub."""
    url = "https://api.github.com/repos/apptainer/apptainer/releases/latest"
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        return data["tag_name"].lstrip("v")  # e.g., "1.3.2"
    except Exception:
        return None

def version_tuple(v):
    return tuple(int(x) for x in v.split("."))

@contextmanager
def pushd(new_dir):
    prev = Path.cwd()
    os.chdir(new_dir)
    try:
        yield
    finally:
        os.chdir(prev)

def main():
    local_version = get_local_version()
    if local_version is None:
        print("❌ Apptainer is not installed on this system.\n")
        print("👉 To install Apptainer, follow instructions here:")
        print("   https://apptainer.org/docs/admin/main/installation.html")
        sys.exit(1)

    print(f"✅ Found Apptainer version {local_version}")

    latest_version = get_latest_version()
    if latest_version is None:
        print("⚠️ Could not fetch latest Apptainer version (GitHub API issue).")
        print("   Continuing with installed version.")
        return

    if version_tuple(local_version) < version_tuple(latest_version):
        print(f"⚠️ Your Apptainer version ({local_version}) is older than the latest ({latest_version}).")
        print("👉 Update instructions: https://apptainer.org/docs/admin/main/installation.html")
        print("   Continuing anyway...\n")
    else:
        print(f"👍 Apptainer is up to date ({local_version}).")

    # Continue with the rest of your script here
    print("🚀 Running rest of the script...")

    glob_dir = sys.argv[1]
    print(f"INSTALL DIRECTORY: {glob_dir}")

    sys.path.append(os.path.abspath(glob_dir))
    module1 = importlib.import_module("scripts.def_files.rebuild_def_content")
    def_rebuild_file_content = module1.def_rebuild_file_content
    module2 = importlib.import_module("scripts.def_files.process_def_content")
    def_process_file_content = module2.def_process_file_content
    module3 = importlib.import_module("scripts.def_files.PCA_def_content")
    def_pca_file_content = module3.def_pca_file_content

    #from {glob_dir}.scripts.def_files.rebuild_def_content import def_rebuild_file_content
    #from scripts.def_files.process_def_content import def_process_file_content
    #from scripts.def_files.PCA_def_content import def_pca_file_content

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

    def_example_file = f"{glob_dir}/Example/data/input.txt"

    lines = [f"{glob_dir}/Example/data/1765-24.sqlite",
        f"{glob_dir}/Example/data/1766-24.sqlite",
        f"{glob_dir}/Example/data/1767-24.sqlite",]

    with open(def_example_file, "w", encoding="utf-8", newline="") as f:
        for path in lines:
            f.write(f"{path}\n")

    # Install apptainer images from def files
    with pushd(f"{glob_dir}/Apptainer/"):
        os.system("apptainer build 1_LMT_rebuild.sif 1_LMT_rebuild.def")

    with pushd(f"{glob_dir}/Apptainer/"):
        os.system("apptainer build 2_LMT_processing.sif 2_LMT_processing.def")

    with pushd(f"{glob_dir}/Apptainer/"):
        os.system("apptainer build 3_LMT_pca.sif 3_LMT_pca.def")

        #sif = Path(glob_dir) / "Apptainer" / "1_LMT_rebuild.sif"
        #dfile = Path(glob_dir) / "Apptainer" / "1_LMT_rebuild.def"    
        #os.system(f"apptainer build {shlex.quote(str(sif))} {shlex.quote(str(dfile))}")
        #os.system(f"apptainer build {glob_dir}/Apptainer/2_LMT_processing.sif {glob_dir}/Apptainer/2_LMT_processing.def")
        #os.system(f"apptainer build {glob_dir}/Apptainer/3_LMT_pca.sif {glob_dir}/Apptainer/3_LMT_pca.def")
        
        # Install apptainer images from cloud.sylabs.io
        #os.system(f"apptainer build {glob_dir}/Apptainer/1_LMT_rebuild.sif library://daleannear/mouseking/lmtrebuild")
        #os.system(f"apptainer build {glob_dir}/Apptainer/2_LMT_processing.sif library://daleannear/mouseking/lmtprocess")
        #os.system(f"apptainer build {glob_dir}/Apptainer/3_LMT_pca.sif library://daleannear/mouseking/lmtpca")

if __name__ == "__main__":
    main()