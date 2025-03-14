include { ArgsCLI } from '../../../modules/local/utils'

workflow stardist {
    take:
    ch_patches
    config

    main:
    stardist_args = ArgsCLI(config.segmentation.stardist)

    ch_patches
        .map { meta, sdata_path, patches_file_image -> [meta, sdata_path, patches_file_image.text.trim().toInteger()] }
        .flatMap { meta, sdata_path, n_patches -> (0..<n_patches).collect { index -> [meta, sdata_path, stardist_args, index, n_patches] } }
        .set { ch_stardist }

    ch_segmented = patchSegmentation(ch_stardist).map { meta, sdata_path, _out, n_patches -> [groupKey(meta.sdata_dir, n_patches), [meta, sdata_path]] }.groupTuple().map { it -> it[1][0] }

    (ch_resolved, _out) = resolve(ch_segmented)

    emit:
    ch_resolved
}


process patchSegmentation {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://jeffquinnmsk/sopa:latest'
        : 'docker.io/jeffquinnmsk/sopa:latest'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/stardist_boundaries/${index}.parquet"), val(n_patches)

    script:
    """
    sopa segmentation stardist ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}

process resolve {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://jeffquinnmsk/sopa:latest'
        : 'docker.io/jeffquinnmsk/sopa:latest'}"

    input:
    tuple val(meta), path(sdata_path)

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/stardist_boundaries"

    script:
    """
    sopa resolve stardist ${sdata_path}
    """
}
