#!/usr/bin/env nextflow

//Set Nextflow work directory
MouseKingDir = "${projectDir}/.."

//Required pipeline parameters
params.input_file = "${MouseKingDir}/Example/data/sqlite_file_list.txt"
params.manifest = "${MouseKingDir}/Example/data/LMT_manifest.txt"
params.save_name = "Nextflow_test"
params.output = "${MouseKingDir}/Example/results/"

//Pipeline parameters (We reccommend using the below defaults)
params.time_file = "NULL" // If a time file is provided, the exact time of day can be calculated for each event
params.event_frame_filter = 15 // 15 means that any event shorter than 15 frames (0.5 seconds) will be filtered out
params.ref = "NULL" //Reference group for effect size calculation

//Apptainer image parameters
params.appimage_1_LMT = "${MouseKingDir}/Apptainer/1_LMT_rebuild.sif"
params.appimage_2_LMT = "${MouseKingDir}/Apptainer/2_LMT_processing.sif"
params.appimage_3_LMT = "${MouseKingDir}/Apptainer/3_LMT_pca.sif"

include { ExtractTables } from './MouseKing_main.nf'
include { PostProcessing } from './MouseKing_main.nf'
include { pcaVisualisation } from './MouseKing_main.nf'
include { CheckTheStatistaks } from './MouseKing_main.nf'

workflow {
    input_file = Channel.fromPath(params.input_file).splitCsv().flatten()
    
    extract_output =  ExtractTables(input_file).collect()

    //Run step 2 of the LMT pipeline
    processing_output = PostProcessing(extract_output)

    //Run step 3 of the LMT pipeline
    pca_output = pcaVisualisation(processing_output)

    bigshaq_output = CheckTheStatistaks(pca_output)
}
