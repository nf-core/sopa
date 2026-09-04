process PATCH_SEGMENTATION_PROSEG {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8c/8c0faf5cf08d20693c45ada9db3c89515ca93be8d6ed5114d022f9333972021d/data'
:         'community.wave.seqera.io/library/python_rust-proseg_sopa:882ce832e7302576' }"

    input:
    tuple val(meta), path(sdata_path), path(patches_file_transcripts)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "versions.yml"

    script:
    """
    export ANNDATA_ALLOW_WRITE_NULLABLE_STRINGS=0

    sopa segmentation proseg ${sdata_path} ${cli_arguments}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        proseg: \$(proseg --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
