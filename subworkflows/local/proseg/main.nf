include { PATCH_SEGMENTATION_PROSEG } from '../../../modules/local/patch_segmentation_proseg'
include { argsCLI } from '../../../modules/local/utils'

workflow PROSEG {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    (ch_segmented, versions) = PATCH_SEGMENTATION_PROSEG(ch_patches, argsCLI("proseg"))

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_segmented
    ch_versions
}
