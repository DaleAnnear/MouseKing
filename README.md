<p align="center">
  <a href="" rel="noopener">
 <img width=300px height=300px src="https://github.com/DaleAnnear/MouseKing/blob/main/LICENSE/imgs/logo2.png" alt="Project logo"></a>
</p>

<h3 align="center">MouseKing</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![GitHub Issues](https://img.shields.io/github/issues/DaleAnnear/MouseKing.svg)](https://github.com/DaleAnnear/MouseKing/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/DaleAnnear/MouseKing.svg)](https://github.com/DaleAnnear/MouseKing/pulls)
<!-- [![License](https://img.shields.io/badge/license-idontknow-blue)](/LICENSE) -->

</div>

---

<p align="center"> A next-generation mouse phenotyping project.
    <br> 
</p>

## 📝 Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Usage](#usage)
- [Built Using](#built_using)
- [Authors](#authors)
- [Acknowledgments](#acknowledgement)

## 🧐 About <a name = "about"></a>

Welcome to MouseKing! The eminent software pipeline to facilitate the data analysis of the next generation of mouse behaviour phenotyping through the LiveMouseTracker (LMT) platform.


## 🏁 Getting Started <a name = "getting_started"></a>

The following instructions will help you to set up the MouseKing pipeline.

### Prerequisites

The only Prerequisites for MouseKing are a Linux system and the installation of the latest versions of [Docker](https://https://www.docker.com/) and [Nextflow](https://www.nextflow.io/). Please follow the links below for more information on the installation of these packages.

- [INSTALL Docker](https://docs.docker.com/engine/install/)

- [INSTALL Nextflow](https://www.nextflow.io/docs/latest/install.html)

### Installing

The below step by step guide will help you to install the MouseKing software.

1. Clone or downlaod the MouseKing repository

To clone the MouseKing repository using ```git``` navigate to the directory on your system where you would like to install in repository and execute the following command:

```
git clone https://github.com/DaleAnnear/MouseKing.git
```

Alternatively, you can downloand a zip of the MouseKing repository from the GitHub website. Download the .zip file to a directory of your choice and extract the repository.  

2. chmod MouseKing to allow for execution

Naviage into the MouseKing directory cloned from Github.

```
cd MouseKing
```

Once there use the following script to allow for command line execution of MouseKing

```
chmod +x MouseKing
```

3. Add MouseKing to your path

Ensure your current working directory is your MouseKing directory

Next add the MouseKing direcory to your PATH so that it may be exectued from any location  
**NOTE:** Replace "/your/directory/path/" with the path on your system which contians the the MouseKing repository

```
echo 'export PATH="$PATH:/your/directory/path/MouseKing"' >> ~/.bashrc && source ~/.bashrc
```

4. Install MouseKing docker images

To fully install MouseKing and the required environments, there are two options. The docker images can be built locally through docker or downloaded from dockerhub (https://hub.docker.com/repository/docker/daleannear/mouseking/general). Both options can be handled and managed by MouseKing.

4.1 For the local installation, run:

```
MouseKing install
```

or

```
MouseKing install local
```

4.2 For the online installation, run:

```
MouseKing install online
```

**NOTE:** To use the online installation you may need to log in to DockerHub.

## 🔧 Running the tests <a name = "tests"></a>

You can test if the the MouseKing pipeline is installed correctly by executing the below command.  
**NOTE:** *When using MouseKing you **MUST** supply full paths for the supplied files and directories to be utilised during your run. This is due to the mounting requirment of container images.*

```
MouseKing royale -i $YOUR_PATH/MouseKing/Example/data/input.txt -m $YOUR_PATH/MouseKing/Example/data/Example_manifest.txt -s MouseKing_Example -o $YOUR_PATH/MouseKing/Example/results
```

## 🎈 Usage <a name="usage"></a>

By running MouseKing:

```
MouseKing
```

You should see the following output in your console:

```
The available commands are:
    royale                  Executes the full MouseKing pipeline
    integrity               Checks the integrity of the provided LMT SQlite files
    rebuild                 Rebuilds all detected mouse events in the provided LMT SQlite files
    extract                 Extracts the EVENT and ANIMAL tables from the provided LMT SQlite files
    processing              Performs processing and filtering of the extracted LMT data contained...
    pca                     Constructs PCA plots for the provided processed LMT data
```

The "royale" command runs the entire MouseKing pipeline. By executing the follwing command:

```
MouseKing royale --help
```

The following output should be seen in your console:

```
Usage: MouseKing royale [options]

Options:
  -i  Input file containg full paths to LMT SQlite files to be processed (required)
  -m  File path to the mouse cage manifest (required)
  -s  Save name for the batch of SQlite files to be processed (required)
  -o  Path to the desired output directory (required)
  -f  Frame filter - DEFAULT RECOMMENDED (default: 15)
  -t  Time file - DEFAULT RECOMMENDED (default: NULL)

Example:
  MouseKing royale -i Example/data/input.txt -m Example/data/Example_manifest.txt -s MouseKing_Example -o Example/results
```

The format of the input file should appear as follows:

```
/home/user/storage/LMT/sqlite_files/Cage_1.sqlite
/home/user/storage/LMT/sqlite_files/Cage_2.sqlite
/home/user/storage/LMT/sqlite_files/Cage_3.sqlite
```

For the cage manifest file, while TSV format is reccomened CSV can also be used. The coulmn headings "RFID", "Condition", and "Cage" **MUST** be provided exactly as outlined. The headings **ARE** case sensitive. The format for the cage manifest should appear as follows:

```
RFID	Condition	Cage
002028193194	WT	1765-24
002028193199	WT	1765-24
002028193230	KO	1765-24
```

The other MouseKing commands (integrity, rebuild, extract, processing, and pca) can be used to execute the specific steps of the pipeline individually. For more information on each step you can execute, run the following:

```
MouseKing <command> --help
```

## ⛏️ Built Using <a name = "built_using"></a>

- [R](https://www.r-project.org/)       - Code
- [Python](https://www.python.org/)     - Code
- [Docker](https://docker.com/)         - Environment and reproducibility
- [Nextflow](https://www.nextflow.io/)  - Workflow management

## ✍️ Authors <a name = "authors"></a>

- Mathijs van der Lei
- Julia Gauglitz
- Frank Kooy
- Wout Bittremieux
- Dale J. Annear [@DaleAnnear](https://github.com/DaleAnnear)

## 🎉 Acknowledgements <a name = "acknowledgement"></a>

We thank the original developers of the Live Mouse Tracker system at Institut Pasteur ([research.pasteur.fr/en/tool/live-mouse-tracker](https://research.pasteur.fr/en/tool/live-mouse-tracker/)). Specifically, we would like to acknowledge the team leads [Fabrice de Chaumont](https://research.pasteur.fr/en/member/fabrice-de-chaumont/) and [Thomas Bourgeron](https://research.pasteur.fr/en/member/thomas-bourgeron/). Further information on the Live Mouse Tracker system can be found through the links below.

- [Website](https://livemousetracker.org/)
  
- [GitHub](https://github.com/fdechaumont/lmt-analysis)
  
- [Real-time analysis of the behaviour of groups of mice via a depth-sensing camera and machine learning](https://www.nature.com/articles/s41551-019-0396-1.epdf?shared_access_token=8wpLBUUytAaGAtXL96vwIdRgN0jAjWel9jnR3ZoTv0MWp3GqbF86Gf14i30j-gtSG2ayVLmU-s57ZbhM2WJjw18inKlRYt31Cg_hLJbPCqlKdjWBImyT1OrH5tewfPqUthmWceoct6RVAL_Vt8H-Og%3D%3D)
