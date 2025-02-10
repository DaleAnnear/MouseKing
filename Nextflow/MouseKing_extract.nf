#!/usr/bin/env nextflow

include { ExtractTables } from './MouseKing_main.nf'

workflow {

    //Run step 1 of the LMT pipeline
    input_file = Channel.fromPath(params.input_file).splitCsv().flatten()
    
    extract_output =  ExtractTables(input_file)
}
