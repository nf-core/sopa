process PATCH_SEGMENTATION_COMSEG {
    label "process_long"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-comseg'
        : 'docker.io/quentinblampey/sopa:latest-comseg'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_counts.h5ad"), path("${sdata_path}/.sopa_cache/transcript_patches/${index}/segmentation_polygons.json"), val(n_patches)

    script:
    """
    sopa segmentation comseg ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}

process RESOLVE_COMSEG {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-comseg'
        : 'docker.io/quentinblampey/sopa:latest-comseg'}"

    input:
    tuple val(meta), path(sdata_path)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/comseg_boundaries"
    path "versions.yml"

    script:
    """
    sopa resolve comseg ${sdata_path} ${cli_arguments}

    rm -r ${sdata_path}/.sopa_cache/transcript_patches  || true    # cleanup large comseg files

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        comseg: \$(python -c "import comseg; print(comseg.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
