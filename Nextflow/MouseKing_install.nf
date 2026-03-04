#!/usr/bin/env nextflow

params.install_dir = "${projectDir}"

process BuildSIF_Rebuild{
    script:

    """
    cd '${params.install_dir}/src'
    docker build -f Dockerfile.rebuild -t lmt_rebuild:1.0 .
    """
}

process BuildSIF_Process{
    script:

    """
    cd '${params.install_dir}/src'
    docker build -f Dockerfile.procesing -t lmt_processing:1.0 .
    """
}

process BuildSIF_PCA{
    script:

    """
    cd '${params.install_dir}/src'
    docker build -f Dockerfile.pca -t lmt_pca:1.0 .
    """
}

workflow {
    buildDEF_out =  BuildDEF(params.install_dir)

    BuildSIF_Rebuild(buildDEF_out)
    BuildSIF_Process(buildDEF_out)
    BuildSIF_PCA(buildDEF_out)
}
