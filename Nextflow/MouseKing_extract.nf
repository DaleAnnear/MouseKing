#!/usr/bin/env nextflow

//Set Nextflow work directory
workDir = "./work"

checkDir = "${projectDir}/"

include { ExtractTables } from './MouseKing_main.nf'

workflow {
    println "The parameter is: ${checkDir}"

    //Run step 1 of the LMT pipeline
    input_file = Channel.fromPath(params.input_file).splitCsv().flatten()
    
    extract_output =  ExtractTables(input_file)
}
