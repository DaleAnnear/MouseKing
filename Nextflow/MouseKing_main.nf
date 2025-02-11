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

//Apptainer image parameters
params.appimage_1_LMT = "${MouseKingDir}/Apptainer/1_LMT_rebuild.sif"
params.appimage_2_LMT = "${MouseKingDir}/Apptainer/2_LMT_processing.sif"
params.appimage_3_LMT = "${MouseKingDir}/Apptainer/3_LMT_pca.sif"

process CheckIntegrity {
    container 'apptainer'

    publishDir "${params.output}/logs", pattern: '*.txt', mode: 'copy'

    input:
        path input_file

    output:
        file "LMT_1.1_CheckIntegrity_log-${params.save_name}_${input_file.simpleName}.txt"
        path input_file, optional: true

    script:
    """
    apptainer run '${params.appimage_1_LMT}' CheckIntegrity '${input_file}' > 'LMT_1.1_CheckIntegrity_log-${params.save_name}_${input_file.simpleName}.txt'
    """
}

process RebuildScript {
    container 'apptainer'

    publishDir "${params.output}/logs", pattern: '*.txt', mode: 'copy'

    input:
        path input_file

    output:
        file "LMT_1.2_RebuildAllEvents_log-${params.save_name}_${input_file.simpleName}.txt"
        path input_file, optional: true

    script:
    """
    apptainer run '${params.appimage_1_LMT}' RebuildAllEvents -f '${input_file}' > 'LMT_1.2_RebuildAllEvents_log-${params.save_name}_${input_file.simpleName}.txt'
    """
}

process ExtractTables {
    container 'apptainer'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path input_file

    output:
        file "LMT_1.3_ExtractTables_log-${input_file.simpleName}_${params.save_name}.txt"

    script:
    """
    apptainer run '${params.appimage_1_LMT}' GetTables -f '${input_file}' -s ${params.save_name} -o '${params.output}' > 'LMT_1.3_ExtractTables_log-${input_file.simpleName}_${params.save_name}.txt'
    """
}

process PostProcessing {
    container 'apptainer'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path ExtractTables_log

    output:
        file "LMT_2_PostProcessing_log-${params.save_name}.txt"
    
    script:
    """
    apptainer run '${params.appimage_2_LMT}' -i '${params.output}' -c '${params.manifest}' -s '${params.save_name}' -t '${params.time_file}' -f ${params.event_frame_filter} -o '${params.output}' > 'LMT_2_PostProcessing_log-${params.save_name}.txt'
    """
}

process pcaVisualisation {
    container 'apptainer'

    publishDir "${params.output}/logs", mode: 'copy'

    input:
        path PostProcessing_log

    output:
        file "LMT_3_PCA_visualisation_log-${params.save_name}.txt"
    
    script:
    """
    apptainer run '${params.appimage_3_LMT}' -i '${params.output}' -c '${params.manifest}' -s '${params.save_name}' -o '${params.output}' > 'LMT_3_PCA_visualisation_log-${params.save_name}.txt'
    """
}

workflow {
    //Run step 1 of the LMT pipeline
    input_file = Channel.fromPath(params.input_file).splitCsv().flatten()
    
    check_integrity_output =  CheckIntegrity(input_file)

    // Filter the CheckIntegrity output to proceed only if the last line contains "SUCCESS"
    valid_outputs = check_integrity_output[0].filter { file ->
        def lastLine = file.text.readLines().last()
        lastLine.contains("Integrity check passed: OK")
    }

    valid_sql = valid_outputs ? check_integrity_output[1] : null

    rebuild_output = RebuildScript(valid_sql)

    extract_output = ExtractTables(rebuild_output[1]).collect()

    //Run step 2 of the LMT pipeline
    processing_output = PostProcessing(extract_output)

    //Run step 3 of the LMT pipeline
    pca_output = pcaVisualisation(processing_output)

}
