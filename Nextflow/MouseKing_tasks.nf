def sqliteInputs(input_file) {
    return channel.fromPath(input_file, checkIfExists: true)
        .splitCsv(quote: '"')
        .flatten()
        .map { entry -> entry.trim() }
        .filter { entry -> entry != '' }
        .map { entry -> file(entry, checkIfExists: true).toRealPath() }
        .unique()
        .ifEmpty { error "No SQLite paths were listed in ${input_file}" }
}

def optionalFile(filename) {
    return filename in ['NULL', 'NA'] ? [] : [file(filename, checkIfExists: true)]
}

def dockerInputMounts() {
    // Make Nextflow's staged symlink targets available inside the container.
    return '''
    input_mounts=()
    for staged in input/* manifest/* start_times.tsv; do
        if [[ -L "$staged" ]]; then
            source_path=$(realpath -- "$staged")
            input_mounts+=(--volume "$source_path:$source_path:ro")
        fi
    done
    '''
}

def pcaStatisticsInputs(results) {
    return results.map { artifacts -> artifacts.findAll { artifact -> artifact.name.endsWith('.csv') } }
}

process CheckIntegrity {
    tag { database.name }
    publishDir({ "${output_dir}/logs" }, mode: 'copy', pattern: '*.txt')

    input:
    path database
    val save_name
    val output_dir
    val image

    output:
    tuple val(source_database), path(log_file), emit: checked

    script:
    source_database = database.toRealPath()
    log_file = "LMT_1.1_CheckIntegrity_log-${save_name}_${database.simpleName}.txt"
    """
    docker run --rm --user "\$(id -u):\$(id -g)" \
        -v "${source_database.parent}:/database" \
        "${image}" CheckIntegrity "/database/${source_database.name}" > "${log_file}"
    """
}

process RebuildScript {
    tag { database.name }
    // Rebuild modifies the original database in place.
    cache false
    publishDir({ "${output_dir}/logs" }, mode: 'copy', pattern: '*.txt')

    input:
    path database
    val save_name
    val output_dir
    val image

    output:
    val source_database, emit: rebuilt
    path log_file, emit: log

    script:
    source_database = database.toRealPath()
    log_file = "LMT_1.2_RebuildAllEvents_log-${save_name}_${database.simpleName}.txt"
    """
    docker run --rm --user "\$(id -u):\$(id -g)" \
        -v "${source_database.parent}:/database" \
        "${image}" RebuildAllEvents -f "/database/${source_database.name}" > "${log_file}"
    """
}

process ExtractTables {
    tag { database.name }
    publishDir({ "${output_dir}/logs" }, mode: 'copy', pattern: '*.txt')
    publishDir({ output_dir }, mode: 'copy', pattern: 'tables/*.csv')

    input:
    path database
    val save_name
    val output_dir
    val image

    output:
    path 'tables/*.csv', optional: true, emit: tables
    path log_file, emit: log

    script:
    def source_database = database.toRealPath()
    log_file = "LMT_1.3_ExtractTables_log-${database.simpleName}_${save_name}.txt"
    """
    docker run --rm --user "\$(id -u):\$(id -g)" \
        -v "${source_database.parent}:/database" -v "\$PWD:/mouseking" \
        "${image}" GetTables -f "/database/${source_database.name}" -s "${save_name}" -o /mouseking \
        > "${log_file}"
    """
}

process PostProcessing {
    stageInMode { input_stage_mode }
    publishDir({ "${output_dir}/logs" }, mode: 'copy', pattern: '*.txt')
    publishDir({ output_dir }, mode: 'copy', pattern: 'processed/*')

    input:
    path 'input/*'
    path manifest, stageAs: 'manifest/*'
    path time_file, stageAs: 'start_times.tsv'
    val frame_filter
    val save_name
    val output_dir
    val image
    val input_stage_mode

    output:
    path 'processed/*', emit: processed
    path log_file, emit: log

    script:
    def time_arg = time_file ? '/mouseking/start_times.tsv' : 'NULL'
    log_file = "LMT_2_PostProcessing_log-${save_name}.txt"
    """
    ${dockerInputMounts()}
    docker run --rm --user "\$(id -u):\$(id -g)" -v "\$PWD:/mouseking" "\${input_mounts[@]}" \
        "${image}" -i /mouseking/input -c "/mouseking/${manifest}" -s "${save_name}" \
        -t "${time_arg}" -f "${frame_filter}" -o /mouseking > "${log_file}"
    """
}

process PcaVisualisation {
    stageInMode { input_stage_mode }
    publishDir({ "${output_dir}/logs" }, mode: 'copy', pattern: '*.txt')
    publishDir({ output_dir }, mode: 'copy', pattern: 'multivariate/*')

    input:
    path 'input/*'
    path manifest, stageAs: 'manifest/*'
    val save_name
    val output_dir
    val image
    val log_prefix
    val input_stage_mode

    output:
    path 'multivariate/*', arity: '1..*', emit: results
    path log_file, emit: log

    script:
    log_file = "${log_prefix}_log-${save_name}.txt"
    """
    ${dockerInputMounts()}
    docker run --rm --user "\$(id -u):\$(id -g)" -v "\$PWD:/mouseking" "\${input_mounts[@]}" \
        "${image}" PCA -i /mouseking/input -c "/mouseking/${manifest}" -s "${save_name}" -o /mouseking \
        > "${log_file}"
    """
}

process PcaStatistics {
    stageInMode 'symlink'
    publishDir({ "${output_dir}/logs" }, mode: 'copy', pattern: '*.txt')
    publishDir({ output_dir }, mode: 'copy', pattern: 'multivariate/*')

    input:
    path 'input/*'
    val ref
    val save_name
    val output_dir
    val image

    output:
    path 'multivariate/*', emit: results
    path log_file, emit: log

    script:
    def ref_option = ref == 'NULL' ? '' : "-r \"${ref}\""
    log_file = "LMT_3.2_PCA_statistics_log-${save_name}.txt"
    """
    ${dockerInputMounts()}
    docker run --rm --user "\$(id -u):\$(id -g)" -v "\$PWD:/mouseking" "\${input_mounts[@]}" \
        "${image}" BigShaq -i /mouseking/input -s "${save_name}" -o /mouseking ${ref_option} \
        > "${log_file}"
    """
}

process UnivariateStatistics {
    stageInMode { input_stage_mode }
    publishDir({ "${output_dir}/logs" }, mode: 'copy', pattern: '*.txt')
    publishDir({ output_dir }, mode: 'copy', pattern: 'univariate/*')

    input:
    path 'input/*'
    path manifest, stageAs: 'manifest/*'
    val save_name
    val output_dir
    val image
    val log_prefix
    val input_stage_mode

    output:
    path 'univariate/*', emit: results
    path log_file, emit: log

    script:
    log_file = "${log_prefix}_log-${save_name}.txt"
    """
    ${dockerInputMounts()}
    docker run --rm --user "\$(id -u):\$(id -g)" -v "\$PWD:/mouseking" "\${input_mounts[@]}" \
        "${image}" SmallShaq -i /mouseking/input -m "/mouseking/${manifest}" -s "${save_name}" -o /mouseking \
        > "${log_file}"
    """
}

workflow AnalyseDatabases {
    take:
    databases
    save_name
    output_dir
    manifest_file
    time_file
    frame_filter
    ref
    rebuild_image
    processing_image
    statistics_image

    main:
    manifest = file(manifest_file, checkIfExists: true)
    ExtractTables(databases, save_name, output_dir, rebuild_image)
    tables = ExtractTables.out.tables.collect(sort: true)
        .ifEmpty { error 'No ANIMAL or EVENT tables were extracted' }

    PostProcessing(tables, manifest, optionalFile(time_file), frame_filter, save_name, output_dir, processing_image, 'symlink')

    PcaVisualisation(PostProcessing.out.processed, manifest, save_name, output_dir, statistics_image,
        'LMT_3.1_PCA_visualisation', 'symlink')
    PcaStatistics(pcaStatisticsInputs(PcaVisualisation.out.results), ref, save_name, output_dir, statistics_image)
    UnivariateStatistics(PostProcessing.out.processed, manifest, save_name, output_dir, statistics_image,
        'LMT_3.3_Uni_statistics', 'symlink')
}
