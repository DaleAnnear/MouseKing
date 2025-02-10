#!/usr/bin/env nextflow

params.install_dir = "${projectDir}"

process BuildDEF{
    input:
        path params.install_dir    

    script:
    """
    python3 ${params.install_dir}/scripts/LMT_install.py '${params.install_dir}'
    """
}

process BuildSIF_Rebuild{
    script:

    """
    apptainer build '${params.install_dir}/Apptainer/1_LMT_rebuild.sif' '${params.install_dir}/Apptainer/1_LMT_rebuild.def'
    """
}

process BuildSIF_Process{
    script:

    """
    apptainer build '${params.install_dir}/Apptainer/2_LMT_processing.sif' '${params.install_dir}/Apptainer/2_LMT_processing.def'
    """
}

process BuildSIF_PCA{
    script:

    """
    apptainer build '${params.install_dir}/Apptainer/3_LMT_pca.sif' '${params.install_dir}/Apptainer/3_LMT_pca.def'
    """
}

workflow {
    buildDEF_out =  BuildDEF(params.install_dir)

    BuildSIF_Rebuild(buildDEF_out)
    BuildSIF_Process(buildDEF_out)
    BuildSIF_PCA(buildDEF_out)
}
