#!/usr/bin/env nextflow

include { sqliteInputs; AnalyseDatabases } from './MouseKing_tasks'

params.save_name = 'Nextflow_test'

workflow {
    AnalyseDatabases(sqliteInputs(params.input_file), params.save_name, params.output, params.manifest,
        params.time_file, params.event_frame_filter, params.ref,
        params.dockerimage_1_LMT, params.dockerimage_2_LMT, params.dockerimage_3_LMT)
}
