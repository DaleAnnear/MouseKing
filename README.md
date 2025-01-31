<p align="center">
  <a href="" rel="noopener">
 <img width=300px height=300px src="https://github.com/DaleAnnear/MouseKing/blob/main/LICENSE/logo.png" alt="Project logo"></a>
</p>

<h3 align="center">MouseKing</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![GitHub Issues](https://img.shields.io/github/issues/DaleAnnear/MouseKing.svg)](https://github.com/DaleAnnear/MouseKing/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/DaleAnnear/MosueKing.svg)](https://github.com/DaleAnnear/MouseKing/pulls)
[![License](https://img.shields.io/badge/license-idontknow-blue)](/LICENSE)

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

The available commands are:
    royale                  Executes the full MouseKing pipeline
    integrity               Checks the integrity of the provided LMT SQlite files
    rebuild                 Rebuilds all detected mouse events in the provided LMT SQlite files
    extract                 Extracts the EVENT and ANIMAL tables from the provided LMT SQlite files
    processing              Performs processing and filtering of the extracted LMT data contained within the EVENT and ANIMAL tables
    pca                     Constructs PCA plots for the provided processed LMT data

## 🏁 Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

The only Prerequisites for MouseKing are a Linux system and the installation of the latest versions of [Apptainer](https://apptainer.org/) and [Nextflow](https://www.nextflow.io/). Please follow the links below for more information on the installation of these packages.

- [INSTALL Apptainer](https://github.com/apptainer/apptainer/blob/release-1.3/INSTALL.md)

- [INSTALL Nextflow](https://www.nextflow.io/docs/latest/install.html)

### Installing

A step by step series of examples that tell you how to get a development env running.

1. Download or pull repo

```
Step 1
```

2. Build apptainer images

```
Step 2
```

3. Add to path

```
Step 3
```


## 🔧 Running the tests <a name = "tests"></a>

You can test if the the MouseKing pipeline works with the below command. NOTE: The below command MUST be executed within the MouseKing ($YOUR_PATH/MouseKing) directory to execute sucessfully.

```
MouseKing royale -i /Example/data/input.txt -m /Example/data/manifest.json -s MouseKing_Example -o /Example/results
```

Alternativelty, the below command can be run from anywhere, but the full path must be provide for the input arguments.

```
MouseKing royale -i $YOUR_PATH/MouseKing/Example/data/input.txt -m $YOUR_PATH/MouseKing/Example/data/manifest.json -s MouseKing_Example -o $YOUR_PATH/MouseKing/Example/results
```

## 🎈 Usage <a name="usage"></a>

Add notes about how to use the system.

## ⛏️ Built Using <a name = "built_using"></a>

- [R](https://www.r-project.org/) - Code
- [Python](https://www.python.org/) - Code
- [Apptainer](https://apptainer.org/) - Environment and reproducibility
- [Nextflow](https://www.nextflow.io/) - Workflow management

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
