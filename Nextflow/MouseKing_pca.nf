#!/usr/bin/env nextflow

//Set Nextflow work directory
MouseKingDir = "${projectDir}/.."

//Required pipeline parameters
params.input_dir = "${MouseKingDir}/Example/data/"
params.manifest = "${MouseKingDir}/Example/data/LMT_manifest.txt"
params.save_name = "MouseKing_Example"
params.output = "${MouseKingDir}/Example/results/"

//Docker image parameters
params.dockerimage_3_LMT = "daleannear/mouseking:lmt_pca-1.0"

process CheckTheStatistaks_Multivariate_p1 {
    container 'docker'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path input_dir

    output:
        file "LMT_3_PCA_visualisation_log-${params.save_name}.txt"
    
    script:
    """
    docker run --rm \
        -v "${params.input_dir}:${params.input_dir}" \
        -v "${params.output}:${params.output}" \
        -v "${params.manifest}:${params.manifest}" \
        "${params.dockerimage_3_LMT}" \
        PCA -i "${params.input_dir}" -c "${params.manifest}" -s "${params.save_name}" -o "${params.output}" \
        > "LMT_3_PCA_visualisation_log-${params.save_name}.txt"
    """
}


process CheckTheStatistaks_Multivariate_p2 {
    container 'apptainer'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path pcaVisualisation_log

    output:
        file "LMT_3.2_PCA_statistics_log-${params.save_name}.txt"
    
    script:
    """
    docker run --rm \
        -v "${params.output}:${params.output}" \
        -v "${params.manifest}:${params.manifest}" \
        "${params.dockerimage_3_LMT}" \
        BigShaq -i "${params.output}" -s "${params.save_name}" -o "${params.output}" \
        > "LMT_3.2_PCA_statistics_log-${params.save_name}.txt"
    """
}

workflow {
    //Run step 1 of the LMT pipeline
    input_path = Channel.fromPath(params.input_dir)
    
    pca_output =  CheckTheStatistaks_Multivariate_p1(input_path)
    bigshaq_output = CheckTheStatistaks_Multivariate_p2(pca_output)
}
