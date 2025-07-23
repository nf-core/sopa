include { ArgsCLI } from '../../../modules/local/utils'


process PATCH_SEGMENTATION_STARDIST {
    label "process_single"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest-stardist'
        : 'docker.io/quentinblampey/sopa:latest-stardist'}"

    input:
    tuple val(meta), path(sdata_path), val(cli_arguments), val(index), val(n_patches)

    output:
    tuple val(meta), path(sdata_path), path("${sdata_path}/.sopa_cache/stardist_boundaries/${index}.parquet"), val(n_patches)

    script:
    """
    sopa segmentation stardist ${sdata_path} --patch-index ${index} ${cli_arguments}
    """
}

process RESOLVE_STARDIST {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'docker://quentinblampey/sopa:latest'
        : 'docker.io/quentinblampey/sopa:latest'}"

    input:
    tuple val(meta), path(sdata_path)

    output:
    tuple val(meta), path(sdata_path)
    path "${sdata_path}/shapes/stardist_boundaries"
    path "versions.yml"

    script:
    """
    sopa resolve stardist ${sdata_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        stardist: \$(python -c "import stardist; print(stardist.__version__)" 2> /dev/null)
    END_VERSIONS
    """
}
