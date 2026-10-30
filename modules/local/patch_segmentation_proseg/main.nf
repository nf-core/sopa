process PATCH_SEGMENTATION_PROSEG {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f4/f4dd5253738b46386b3f515041c30959ca594a4865ae0bd6c83de9d341fef1f6/data'
:         'community.wave.seqera.io/library/python_rust-proseg_sopa:ed334dad70b40e44' }"

    input:
    tuple val(meta), path(sdata_path), path(patches_file_transcripts)
    val cli_arguments

    output:
    tuple val(meta), path(sdata_path)
    path "versions.yml"

    script:
    """
    sopa segmentation proseg ${sdata_path} ${cli_arguments}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sopa: \$(sopa --version)
        proseg: \$(proseg --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
