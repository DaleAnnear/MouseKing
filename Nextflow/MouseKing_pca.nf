#!/usr/bin/env nextflow

include { PcaVisualisation; PcaStatistics; pcaStatisticsInputs } from './MouseKing_tasks'

params.save_name = 'MouseKing_Example'

workflow {
    PcaVisualisation(file(params.input_dir, checkIfExists: true), file(params.manifest, checkIfExists: true),
        params.save_name, params.output, params.dockerimage_3_LMT, 'LMT_3_PCA_visualisation', 'copy')
    PcaStatistics(pcaStatisticsInputs(PcaVisualisation.out.results), params.ref, params.save_name,
        params.output, params.dockerimage_3_LMT)
}
