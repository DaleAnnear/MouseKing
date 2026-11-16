#!/usr/bin/env nextflow

include { sqliteInputs; CheckIntegrity } from './MouseKing_tasks'

params.save_name = 'Nextflow_test'

workflow {
    CheckIntegrity(sqliteInputs(params.input_file), params.save_name, params.output, params.dockerimage_1_LMT)
}
