include { PATCH_SEGMENTATION_BAYSOR } from '../../../modules/local/patch_segmentation_baysor'
include { RESOLVE_BAYSOR } from '../../../modules/local/resolve_baysor'
include { argsCLI } from '../../../modules/local/utils'

workflow BAYSOR {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    baysor_args = argsCLI("baysor")

    ch_patches
        .map { meta, sdata_path, patches_file_transcripts -> [meta, sdata_path, patches_file_transcripts.splitText()] }
        .flatMap { meta, sdata_path, patches_indices -> patches_indices.collect { index -> [meta, sdata_path, baysor_args, index.trim().toInteger(), patches_indices.size] } }
        .set { ch_baysor }

    ch_segmented = PATCH_SEGMENTATION_BAYSOR(ch_baysor)
        .map { meta, sdata_path, counts, polygons, n_patches -> [groupKey(meta.sdata_dir, n_patches), meta, sdata_path, counts, polygons] }
        .groupTuple().map { _key, metas, sdata_paths, counts, polygons -> [metas[0], sdata_paths[0], counts, polygons] }

    (ch_resolved, versions) = RESOLVE_BAYSOR(ch_segmented, argsCLI("resolve"))

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}
