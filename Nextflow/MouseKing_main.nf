#!/usr/bin/env nextflow

include { sqliteInputs; CheckIntegrity; RebuildScript; AnalyseDatabases } from './MouseKing_tasks'

params.save_name = 'Nextflow_test'

workflow {
    databases = sqliteInputs(params.input_file)
    CheckIntegrity(databases, params.save_name, params.output, params.dockerimage_1_LMT)

    valid_databases = CheckIntegrity.out.checked
        .filter { _database, log -> log.text.trim().endsWith('Integrity check passed: OK') }
        .map { database, _log -> database }
        .ifEmpty { error 'No SQLite databases passed the integrity check' }

    RebuildScript(valid_databases, params.save_name, params.output, params.dockerimage_1_LMT)
    AnalyseDatabases(RebuildScript.out.rebuilt, params.save_name, params.output, params.manifest,
        params.time_file, params.event_frame_filter, params.ref,
        params.dockerimage_1_LMT, params.dockerimage_2_LMT, params.dockerimage_3_LMT)
}
