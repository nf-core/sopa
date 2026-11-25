process PATCH_SEGMENTATION_PROSEG {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/be/be6adcc639e9ebd74d4bd9f1b373d17537f623c504ae9f126048dd4fec2ab8c2/data'
:         'community.wave.seqera.io/library/python_rust-proseg_sopa:b628e4442a9964df' }"

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
