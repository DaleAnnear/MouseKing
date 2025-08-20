import sys

glob_dir = sys.argv[1]
def_pca_file_content = f"""Bootstrap: docker
From: rocker/r-base:latest

%labels
    Author Dale J. Annear, PhD
    Version v1.0

%help
    This container runs the R script `LMT_PCA_visualisation.R`.

%post
    set -e
    export DEBIAN_FRONTEND=noninteractive

    # Minimal OS deps (download + SSL + tar)
    apt-get update
    apt-get install -y --no-install-recommends \\
        curl \\
        bzip2 \\
        ca-certificates \\
        tar \\
        tzdata
    update-ca-certificates

    # (Optional) set timezone to UTC like your original
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata

    # Install micromamba (static binary)
    mkdir -p /usr/local
    curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest -o /tmp/micromamba.tar.bz2
    tar -xvjf /tmp/micromamba.tar.bz2 -C /usr/local bin/micromamba
    rm -f /tmp/micromamba.tar.bz2
    chmod +x /usr/local/bin/micromamba

    # Create the R environment entirely via conda (no install.packages in R)
    export MAMBA_NO_BANNER=1
    /usr/local/bin/micromamba create -y -p /opt/conda/envs/LMT_pca \\
        -c conda-forge -c bioconda \\
        r-base \\
        r-ggplot2 \\
        r-optparse \\
        r-devtools \\
        r-dplyr \\
        r-tidyr \\
        r-tidyverse \\
        r-data.table \\
        r-corrr \\
        r-ggcorrplot \\
        r-factominer \\
        r-factoextra \\
        r-ggforce \\
        r-effsize \\
        bioconductor-m3c

    # Tidy up
    /usr/local/bin/micromamba clean -a -y
    apt-get clean
    rm -rf /var/lib/apt/lists/*

%environment
    # Use the env without 'conda activate'
    export PATH=/opt/conda/envs/LMT_pca/bin:/usr/local/bin:\\$PATH

%files
    "{glob_dir}/scripts/LMT_PCA_visualisation.R" /workspace/LMT_PCA_visualisation.R
    "{glob_dir}/scripts/LMT_Statistaks.R" /workspace/LMT_Statistaks.R
    "{glob_dir}/scripts/LMT_functions.R" /workspace/LMT_functions.R

%runscript
    #!/bin/bash
    # Check the first argument to decide which script to execute
    case "$1" in
        PCA)
            shift # Remove the first argument
            exec /opt/conda/envs/LMT_pca/bin/Rscript /workspace/LMT_PCA_visualisation.R "$@" # Pass remaining arguments to PCA
            ;;
        BigShaq)
            shift # Remove the first argument
            exec /opt/conda/envs/LMT_pca/bin/Rscript /workspace/LMT_Statistaks.R "$@" # Pass remaining arguments to BigShaq
            ;;
        *)
            echo "Usage: apptainer run 3_LMT_pca.sif [PCA|BigShaq] [script arguments]"
            exit 1
            ;;
    esac
    """