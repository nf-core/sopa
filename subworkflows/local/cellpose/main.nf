include { PATCH_SEGMENTATION_CELLPOSE } from '../../../modules/local/patch_segmentation_cellpose'
include { RESOLVE_CELLPOSE } from '../../../modules/local/resolve_cellpose'
include { argsCLI } from '../../../modules/local/utils'

workflow CELLPOSE {
    take:
    ch_patches

    main:
    ch_versions = channel.empty()

    cellpose_args = argsCLI("cellpose")

    ch_patches
        .map { meta, sdata_path, patches_file_image -> [meta, sdata_path, patches_file_image.text.trim().toInteger()] }
        .flatMap { meta, sdata_path, n_patches -> (0..<n_patches).collect { index -> [meta, sdata_path, cellpose_args, index, n_patches] } }
        .set { ch_cellpose }

    ch_segmented = PATCH_SEGMENTATION_CELLPOSE(ch_cellpose)
        .map { meta, sdata_path, parquet, n_patches -> [groupKey(meta.sdata_dir, n_patches), meta, sdata_path, parquet] }
        .groupTuple().map { _key, metas, sdata_paths, parquets -> [metas[0], sdata_paths[0], parquets] }

    (ch_resolved, versions) = RESOLVE_CELLPOSE(ch_segmented)

    ch_versions = ch_versions.mix(versions)

    emit:
    ch_resolved
    ch_versions
}
