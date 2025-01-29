#!/usr/bin/env nextflow

//Set Nextflow work directory
workDir = "${projectDir}/work"

include { CheckIntegrity } from './MouseKing_main.nf'

workflow {
    //Run step 1 of the LMT pipeline
    input_file = Channel.fromPath(params.input_file).splitCsv().flatten()
    
    check_integrity_output =  CheckIntegrity(input_file)
}
