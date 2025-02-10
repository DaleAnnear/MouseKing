import sys, os

glob_dir = sys.argv[1]
print(f"INSTALL DIRECTORY: {glob_dir}")

def_rebuild_file_content = f"""Bootstrap: docker
From: ubuntu:20.04

%labels
    Author Dale J. Annear, PhD
    Version v1.0

%post
    # Install required dependencies
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \\
        wget \\
        bzip2 \\
        ca-certificates \\
        libglib2.0-0 \\
        libxext6 \\
        libsm6 \\
        libxrender1

    # Install Miniconda
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p /opt/conda
    rm /tmp/miniconda.sh
    /opt/conda/bin/conda clean -tipy

    # Add Conda to PATH
    if [ ! -f /etc/profile.d/conda.sh ]; then
        echo "export PATH=/opt/conda/bin:\\$PATH" >> /etc/profile.d/conda.sh
    fi

    # Create Conda environment from the environment.yml file
    /opt/conda/bin/conda env create --name LMT_rebuild -f /workspace/1_LMT_rebuild.yml

%environment
    export PATH=/opt/conda/bin:$PATH
    source activate LMT_rebuild

%runscript
    #!/bin/bash
    case "$1" in
        CheckIntegrity)
            shift
            exec python3 /workspace/LMT_Check_Integrity.py "$@"
            ;;
        RebuildAllEvents)
            shift
            exec Rscript /workspace/LMT_rebuild_all_events.R "$@"
            ;;
        GetTables)
            shift
            exec Rscript /workspace/LMT_Extract_Tables.R "$@"
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

%test
    /opt/conda/bin/conda --version
    /opt/conda/bin/conda env list
"""

def_process_file_content = f"""Bootstrap: docker
From: ubuntu:20.04

%labels
    Author Dale J. Annear, PhD
    Version v1.0

%post
    #DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \\
        wget \\
        bzip2 \\
        ca-certificates \\
        libglib2.0-0 \\
        libxext6 \\
        libsm6 \\
        libxrender1

    # Install Miniconda
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p /opt/conda
    rm /tmp/miniconda.sh
    /opt/conda/bin/conda clean -tipy

    # Add Conda to PATH
    if [ ! -f /etc/profile.d/conda.sh ]; then
        echo "export PATH=/opt/conda/bin:\\$PATH" >> /etc/profile.d/conda.sh
    fi

    # Create Conda environment from the environment.yml file
    /opt/conda/bin/conda env create --name LMT_processing -f /workspace/2_LMT_processing.yml

%environment
    export PATH=/opt/conda/bin:$PATH
    source activate LMT_processing

%runscript
    exec Rscript /workspace/LMT_post_rebuild_processing.R "$@"

%files
    "{glob_dir}/Apptainer/2_LMT_processing.yml" /workspace/2_LMT_processing.yml
    "{glob_dir}/scripts/LMT_post_rebuild_processing.R" /workspace/LMT_post_rebuild_processing.R
    "{glob_dir}/scripts/LMT_functions.R" /workspace/LMT_functions.R

%test
    /opt/conda/bin/conda --version
    /opt/conda/bin/conda env list


"""

def_pca_file_content = f"""Bootstrap: docker
From: rocker/r-base:latest

%labels
    Author Dale J. Annear, PhD
    Version v1.0

%help
    This container runs the R script `vis.R`.

%post
  # Update and install required dependencies
  apt-get update && apt-get install -y \\
      libcurl4-openssl-dev \\
      libssl-dev \\
      libxml2-dev \\
      gfortran \\
      make \\
      wget \\
      curl \\
      git \\
      cmake \\
      r-base-dev \\
      r-cran-ggplot2 \\
      r-cran-optparse \\
      r-cran-devtools \\
      r-cran-dplyr \\
      r-cran-tidyr \\
      r-cran-tidyverse \\
      r-cran-data.table \\
      tzdata  # Install tzdata to configure the timezone
  
  # Set the timezone to UTC (or another preferred timezone)
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime
  dpkg-reconfigure --frontend noninteractive tzdata

  # Ensure R and Rscript are available (they are usually installed with R)
  R -e "if(!require('base')) install.packages('base')"

  # Install R package dependencies (optional)
  R -e "install.packages('BiocManager', dependencies = TRUE)"
  R -e "install.packages('corrr', dependencies = TRUE)"
  R -e "install.packages('ggcorrplot', dependencies = TRUE)"
  R -e "install.packages('FactoMineR', dependencies = TRUE)"
  R -e "install.packages('factoextra', dependencies = TRUE)"

  R -e "BiocManager::install('M3C')"


  # Clean up to reduce image size
  apt-get clean && rm -rf /var/lib/apt/lists/*

%files
    "{glob_dir}/scripts/LMT_PCA_visualisation.R" /workspace/LMT_PCA_visualisation.R
    "{glob_dir}/scripts/LMT_functions.R" /workspace/LMT_functions.R

%environment
    export PATH=/usr/bin:$PATH

%runscript
    echo "Running Rscript: LMT_PCA_visualisation.R"
    exec /usr/bin/Rscript /workspace/LMT_PCA_visualisation.R "$@"

"""

def_example_file_content = f"""{glob_dir}/Example/1765-24.sqlite
{glob_dir}/Example/1766-24.sqlite
{glob_dir}/Example/1767-24.sqlite
{glob_dir}/Example/decoy_file.sqlite
"""

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
with open(def_example_file, "w") as file:
    file.write(def_example_file_content)
    
os.system(f"apptainer build {glob_dir}/Apptainer/1_LMT_rebuild.sif {glob_dir}/Apptainer/1_LMT_rebuild.def")
os.system(f"apptainer build {glob_dir}/Apptainer/2_LMT_processing.sif {glob_dir}/Apptainer/2_LMT_processing.def")
os.system(f"apptainer build {glob_dir}/Apptainer/3_LMT_pca.sif {glob_dir}/Apptainer/3_LMT_pca.def")
