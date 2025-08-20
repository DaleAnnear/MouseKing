import sys

glob_dir = sys.argv[1]
def_process_file_content = f"""Bootstrap: docker
From: ubuntu:20.04

%labels
    Author Dale J. Annear, PhD
    Version v1.0

%post
    set -e
    export DEBIAN_FRONTEND=noninteractive

    # Base deps for downloading/extracting micromamba and SSL certs
    apt-get update
    apt-get install -y --no-install-recommends \\
        curl \\
        bzip2 \\
        ca-certificates \\
        tar \\
        libglib2.0-0 \\
        libxext6 \\
        libsm6 \\
        libxrender1
    update-ca-certificates

    # Install micromamba (static binary)
    mkdir -p /usr/local
    curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest -o /tmp/micromamba.tar.bz2
    tar -xvjf /tmp/micromamba.tar.bz2 -C /usr/local bin/micromamba
    rm -f /tmp/micromamba.tar.bz2
    chmod +x /usr/local/bin/micromamba

    # Create environment from the provided YAML
    export MAMBA_NO_BANNER=1
    /usr/local/bin/micromamba create -y -p /opt/conda/envs/LMT_processing -f /workspace/2_LMT_processing.yml

    # Optional: clean up to shrink image
    /usr/local/bin/micromamba clean -a -y
    apt-get clean
    rm -rf /var/lib/apt/lists/*

%environment
    # Ensure the env is active via PATH (no 'conda activate' needed)
    export PATH=/opt/conda/envs/LMT_processing/bin:/usr/local/bin:\\$PATH

%runscript
    # Run the post-rebuild processing R script by default
    exec Rscript /workspace/LMT_post_rebuild_processing.R "$@"

%files
    "{glob_dir}/Apptainer/2_LMT_processing.yml" /workspace/2_LMT_processing.yml
    "{glob_dir}/scripts/LMT_post_rebuild_processing.R" /workspace/LMT_post_rebuild_processing.R
    "{glob_dir}/scripts/LMT_functions.R" /workspace/LMT_functions.R
    """