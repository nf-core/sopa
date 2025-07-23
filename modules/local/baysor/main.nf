process PATCH_SEGMENTATION_BAYSOR {
    label "process_long"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-baysor'
        : 'docker.io/quentinblampey/sopa:latest-baysor'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_counts.loom"), val(n_patches)

    script:
    """
    if command -v module &> /dev/null; then
        module purge
    fi

    sopa segmentation baysor ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}

process RESOLVE_BAYSOR {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-baysor'
        : 'docker.io/quentinblampey/sopa:latest-baysor'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/baysor_boundaries"
    path "versions.yml"

    script:
    """
    sopa resolve baysor ${sdata_path} ${cli_arguments}

    rm -r ${sdata_path}/.sopa_cache/transcript_patches  || true    # cleanup large baysor files

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        baysor: \$(baysor --version)
    END_VERSIONS
    """
}
