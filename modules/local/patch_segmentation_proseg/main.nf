process PATCH_SEGMENTATION_PROSEG {
    label "process_high"
    tag "${meta.sample}"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'apptainer' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/sopa:2.2.5--7a8340c1f5d41e34-proseg'
        : 'community.wave.seqera.io/library/sopa:2.2.5--77a69d04f8380675-proseg'}"

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
