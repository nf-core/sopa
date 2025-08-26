include { ArgsCLI } from '../../../modules/local/utils'


process PATCH_SEGMENTATION_CELLPOSE {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-cellpose'
        : 'docker.io/quentinblampey/sopa:latest-cellpose'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/cellpose_boundaries/${index}.parquet"), val(n_patches)

    script:
    """
    sopa segmentation cellpose ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}

process RESOLVE_CELLPOSE {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-cellpose'
        : 'docker.io/quentinblampey/sopa:latest-cellpose'}"

    input:
    tuple val(meta), path(sdata_path)

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/cellpose_boundaries"
    path "versions.yml"

    script:
    """
    sopa resolve cellpose ${sdata_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        cellpose: \$(cellpose --version | grep 'cellpose version:' | head -n1 | awk '{print \$3}')
    END_VERSIONS
    """
}
