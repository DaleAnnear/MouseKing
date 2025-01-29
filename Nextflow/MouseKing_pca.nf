#!/usr/bin/env nextflow

//Set Nextflow work directory
MouseKingDir = "${projectDir}/.."

//Required pipeline parameters
params.input_dir = "${MouseKingDir}/Example/data/"
params.manifest = "${MouseKingDir}/Example/data/LMT_manifest.txt"
params.save_name = "MouseKing_Example"
params.output = "${MouseKingDir}/Example/results/"

//Apptainer image parameters
params.appimage_3_LMT = "${MouseKingDir}/Apptainer/3_LMT_pca.sif"

process pca {
    container 'apptainer'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path input_dir

    output:
        file "LMT_3_PCA_visualisation_log-${params.save_name}.txt"
    
    script:
    """
    apptainer run '${params.appimage_3_LMT}' -i '${params.input_dir}' -c '${params.manifest}' -s '${params.save_name}' -o '${params.output}' > 'LMT_3_PCA_visualisation_log-${params.save_name}.txt'
    """
}

workflow {
    //Run step 1 of the LMT pipeline
    input_path = Channel.fromPath(params.input_dir)
    
    pca_output =  pca(input_path)
}
