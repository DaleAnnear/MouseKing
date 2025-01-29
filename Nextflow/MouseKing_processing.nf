#!/usr/bin/env nextflow

//Set Nextflow work directory
MouseKingDir = "${projectDir}/.."

//Required pipeline parameters
params.input_dir = "${MouseKingDir}/Example/data/"
params.manifest = "${MouseKingDir}/Example/data/LMT_manifest.txt"
params.save_name = "MouseKing_Example"
params.output = "${MouseKingDir}/Example/results/"

//Pipeline parameters (We reccommend using the below defaults)
params.time_file = "NULL" // If a time file is provided, the exact time of day can be calculated for each event
params.event_frame_filter = 15 // 15 means that any event shorter than 15 frames (0.5 seconds) will be filtered out

//Apptainer image parameters
params.appimage_2_LMT = "${MouseKingDir}/Apptainer/2_LMT_processing.sif"

process Processing {
    container 'apptainer'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path input_dir

    output:
        file "LMT_2_PostProcessing_log-${params.save_name}.txt"
    
    script:
    """
    apptainer run '${params.appimage_2_LMT}' -i '${params.input_dir}' -c '${params.manifest}' -s '${params.save_name}' -t '${params.time_file}' -f ${params.event_frame_filter} -o '${params.output}' > 'LMT_2_PostProcessing_log-${params.save_name}.txt'
    """
}

workflow {
    //Run step 1 of the LMT pipeline
    input_path = Channel.fromPath(params.input_dir)
    
    processing_output =  Processing(input_path)
}
