import sys

glob_dir = sys.argv[1]
def_rebuild_file_content = f"""Bootstrap: docker
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
        wget \\
        bzip2 \\
        ca-certificates \\
        libglib2.0-0 \\
        libxext6 \\
        libsm6 \\
        libxrender1 \\
        curl \\
        ca-certificates \\
        tar \\
        coreutils \\
        sed
    update-ca-certificates

    # Install micromamba (static binary)
    mkdir -p /usr/local
    curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest -o /tmp/micromamba.tar.bz2
    tar -xvjf /tmp/micromamba.tar.bz2 -C /usr/local bin/micromamba
    rm -f /tmp/micromamba.tar.bz2
    chmod +x /usr/local/bin/micromamba

    # Create the environment from your YAML (no conda/plugins involved)
    export MAMBA_NO_BANNER=1
    /usr/local/bin/micromamba create -y -p /opt/conda/envs/LMT_rebuild -f /workspace/1_LMT_rebuild.yml
    /usr/local/bin/micromamba clean -a -y

%environment
    # Make the envs binaries come first at runtime (no 'conda activate' needed)
    export PATH=/opt/conda/envs/LMT_rebuild/bin:/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

%runscript
    #!/bin/bash
    # Check the first argument to decide which script to execute
    case "$1" in
        CheckIntegrity)
            shift # Remove the first argument
            exec python3 /workspace/LMT_Check_Integrity.py "$@" # Pass remaining arguments to CheckIntegrity
            ;;
        RebuildAllEvents)
            shift # Remove the first argument
            exec Rscript /workspace/LMT_rebuild_all_events.R "$@" # Pass remaining arguments to RebuildAllEvents
            ;;
        GetTables)
            shift # Remove the first argument
            exec Rscript /workspace/LMT_Extract_Tables.R "$@" # Pass remaining arguments to GetTables
            ;;
        *)
            echo "Usage: apptainer run 1_LMT_rebuild.sif [CheckIntegrity|RebuildAllEvents|GetTables] [script arguments]"
            exit 1
            ;;
    esac

%files
    "{glob_dir}/Apptainer/1_LMT_rebuild.yml" /workspace/1_LMT_rebuild.yml
    "{glob_dir}/scripts/LMT_Check_Integrity.py" /workspace/LMT_Check_Integrity.py
    "{glob_dir}/scripts/LMT_Rebuild_All_Events.R" /workspace/LMT_rebuild_all_events.R
    "{glob_dir}/scripts/LMT_Extract_Tables.R" /workspace/LMT_Extract_Tables.R
    "{glob_dir}/scripts/LMT_functions.R" /workspace/LMT_functions.R
    "{glob_dir}/scripts/lmt-analysis-master" /workspace/lmt-analysis-master
    """