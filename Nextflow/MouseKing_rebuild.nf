#!/usr/bin/env nextflow

//Set Nextflow work directory
workDir = "./work"

include { RebuildScript } from './MouseKing_main.nf'

workflow {
    //Run step 1 of the LMT pipeline
    input_file = Channel.fromPath(params.input_file).splitCsv().flatten()
    
    rebuild_output =  RebuildScript(input_file)
}
