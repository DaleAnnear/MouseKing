#!/usr/bin/env nextflow

include { UnivariateStatistics } from './MouseKing_tasks'

params.save_name = 'MouseKing_Example'

workflow {
    UnivariateStatistics(file(params.input_dir, checkIfExists: true), file(params.manifest, checkIfExists: true),
        params.save_name, params.output, params.dockerimage_3_LMT, 'LMT_3.3_uni_statistics', 'copy')
}
