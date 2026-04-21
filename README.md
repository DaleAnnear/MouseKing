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
Welcome to MouseKing! The eminent software pipeline to facilitate the data analysis of the next generation of mouse behaviour phenotyping through the LiveMouseTracker (LMT) platform.

The available commands are:
    royale                  Executes the full MouseKing pipeline
    integrity               Checks the integrity of the provided LMT SQlite files
    rebuild                 Rebuilds all detected mouse events in the provided LMT SQlite files
    extract                 Extracts the EVENT and ANIMAL tables from the provided LMT SQlite files
    processing              Performs processing and filtering of the extracted LMT data contained within the EVENT and ANIMAL tables
    uni                     Performs univariate statistics for the provided processed LMT data
    multi                   Performs multivariate statistics for the provided processed LMT data
    install                 Installs the environment required to run MouseKing
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
  MouseKing royale -i ~/Example/data/input.txt -m ~/Example/data/Example_manifest.txt -s MouseKing_Example -o ~/Example/results

  NOTE: Full paths must be provided
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

If you opt to make use of a time file (TSV), the required format can be seen below. The coulmn headings "Cage", "Treatment", "Start_Time", "Group" **MUST** be provided exactly as outlined. The headings **ARE** case sensitive.

```
Cage  Treatment Start_Time  Group
5761 baseline  14:00:28  vehicle
5761 drug_x  13:53:17  treated
1044 baseline  12:46:39  vehicle
1044 drug_y  13:22:05  treated
```

The other MouseKing commands (integrity, rebuild, extract, processing, and pca) can be used to execute the specific steps of the pipeline individually. For more information on each step you can execute, run the following:

```
MouseKing <command> --help
```

## 🧭 Navigating Results <a name="navigating_results"></a>
After a successful MouseKing royale run, within your specified results directory you should see the following 5 directories:

```
logs  multivariate  processed  tables  univariate
```

In the ```logs``` directory you can find the log files for each of the MouseKing steps. These can be useful for further information and troubleshoooting. Examples of the log files are as follows:
- LMT_1.1_CheckIntegrity_log-{save_name}.txt
- LMT_1.2_RebuildAllEvents_log-{save_name}.txt
- LMT_1.3_ExtractTables_log-{save_name}.txt
- LMT_2_PostProcessing_log-{save_name}.txt
- LMT_3.1_PCA_visualisation_log-{save_name}.txt
- LMT_3.2_PCA_statistics_log-{save_name}.txt
- LMT_3.3_Uni_statistics_log-{save_name}.txt

In the ```tables``` directory you can find the EVENT and ANIMAL tables extracted directly from the LiveMouseTracker sqlite database files. There will be a ANIMAL and EVENT table file for each LMT cage that is analysed. This is the raw data upon which the MouseKing data anylsis takes place. Examples of the table files are as follows:
- cageX_ANIMAL_{save_name}.csv
- cageX_EVENT_{save_name}.csv
- cageY_ANIMAL_{save_name}.csv
- cageY_EVENT_{save_name}.csv

In the ```processed``` directory you can four different files of proccessed, but still realitively raw data regarding your analysed LMT cages. At this point all events with a duration shorter than the deired frame filter (default: 15 frames) have been removed. These files include:
- {save_name}_All_Events_filter_frames_{frame_filter}.csv                 - Contains all the detected behaviour events of all mice across all cages
- {save_name}_Cage_Count_means_filter_frames_{frame_filter}.csv           - Contains the COUNT total, average, and SD of each behaviour type per cage
- {save_name}_Cage_Events_means_filter_frames_{frame_filter}.csv          - Contains the DURATION total, average, and SD of each behaviour type per cage and mouse condition
- {save_name}_Event_Counts_with_duration_filter_frames_frame_filter.csv   - Contains the COUNT and DURATION data for each behaviour type for each individual mouse

In the ```univariate``` directory you will find the results of the univariate statistics. Here comparrisons are made across the different mouse conditions outlined within the provided manifest file. Statistical comparisons are made with the Wilcoxon test and are adjusted for multiple tests by the Bonferroni correction. The ouput files are as follows:
- Univariate_Analysis_Behavioural_Domain_{save_name}.txt  - Contains the raw statisitcal results of the Wilcoxon test and Bonferroni correction for each behaviour type across each possible condition comparrison
- Univariate_Behavioural_Domains{save_name}.tiff          - Graphical illustration of the significant and non-significant behavoural types and domains across the different condition comparrisons

In the ```multivariate``` directroy you will find the results of the multivariate statistics. Here comparrisons are made across the different mouse conditions outlined within the provided manifest file. The conditions are compared through PCA and post hoc analyses are performed by MANNOVA and ANOVA (parametric) or PERMANOVA and Friedman test (non-parametric). The statistical comparrisons were corrected through Bonferroni correction. The ouput files are as follows:
- {save_name}_Normalised_Input.csv                            - Contians the normalised input matrix used to compute the PCA anaylsis
- {save_name}_PCA_data.csv                                    - Contains the data output of the PCA analysis
- {save_name}_PCA_loadings.csv                                - Contains the PCA loading data
- {save_name}_PCA_variances.csv                               - Contains the SD, eigen, and variance values for each computed PC
- {save_name}_PC_Statistics.txt                               - Contains the statistical results comparing the PCA results across the present mouse conditions
- {save_name}_EffectSize_data.csv                             - Contains the effect sizes of different behaviour types for the various mouse conditions across the different PCs
- {save_name}_all_PCA.tiff                                    - PCA of all mice present within the anaylsis
- {save_name}_all_variables.tiff                              - Plot dispalying the variables in the PCA as vectors
- {save_name}_CF_boxplot.tiff                                 - Distribution of the contributing factors across the 5 different behavioural domains 
- {save_name}_Loadings_PC{X}.png                              - The loading of each behaviour for each PC
- {save_name}_PC{X}_Condition_comparison_boxplot.png          - Comparrison of each PC across the present mouse conditions
- {save_name}_Behaviour_effectsize_PC_{X}_{Comparrison}.png   - The effectsize of each behaviour type within each PC 

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
