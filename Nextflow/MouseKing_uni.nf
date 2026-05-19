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

process CheckTheStatistaks_Univariate {
    container 'docker'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path input_dir

    output:
        file "LMT_3.3_uni_statistics_log-${params.save_name}.txt"
    
    script:
    """
    docker run --rm \
        -v "${params.output}:${params.output}" \
        -v "${projectDir}/src/LMT_Univariate_Statistaks.R:/workspace/LMT_Univariate_Statistaks.R" \
        -v "${params.manifest}:${params.manifest}" \
        "${params.dockerimage_3_LMT}" \
        SmallShaq -i "${params.output}" -m "${params.manifest}" -s "${params.save_name}" -o "${params.output}" \
        > "LMT_3.3_uni_statistics_log-${params.save_name}.txt"
    """
}

workflow {
    //Run step 1 of the LMT pipeline
    input_path = Channel.fromPath(params.input_dir)
    
    bigshaq_output = CheckTheStatistaks_Univariate(input_path)
}
