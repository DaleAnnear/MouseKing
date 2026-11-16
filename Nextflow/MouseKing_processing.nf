#!/usr/bin/env nextflow

include { optionalFile; PostProcessing } from './MouseKing_tasks'

params.save_name = 'MouseKing_Example'

workflow {
    PostProcessing(file(params.input_dir, checkIfExists: true), file(params.manifest, checkIfExists: true),
        optionalFile(params.time_file), params.event_frame_filter, params.save_name, params.output,
        params.dockerimage_2_LMT, 'copy')
}
