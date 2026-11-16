#!/usr/bin/env nextflow

include { sqliteInputs; RebuildScript } from './MouseKing_tasks'

params.save_name = 'Nextflow_test'

workflow {
    RebuildScript(sqliteInputs(params.input_file), params.save_name, params.output, params.dockerimage_1_LMT)
}
