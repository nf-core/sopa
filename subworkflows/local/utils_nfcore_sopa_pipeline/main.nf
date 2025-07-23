//
// Subworkflow with functionality specific to the nf-core/sopa pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap } from 'plugin/nf-schema'
include { samplesheetToList } from 'plugin/nf-schema'
include { completionEmail } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary } from '../../nf-core/utils_nfcore_pipeline'
include { imNotification } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE } from '../../nf-core/utils_nextflow_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {
    take:
    version // boolean: Display version and exit
    validate_params // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs // boolean: Do not use coloured log outputs
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir //  string: The output directory where the results will be saved
    input //  string: Path to input samplesheet

    main:

    ch_versions = Channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE(
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1,
    )

    //
    // Validate parameters and generate parameter summary to stdout
    //
    UTILS_NFSCHEMA_PLUGIN(
        workflow,
        validate_params,
        null,
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE(
        nextflow_cli_args
    )

    //
    // Create channel from input file provided through params.input
    //

    Channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
        .map { meta, data_path ->
            if (!meta.fastq_dir) {
                if (!data_path) {
                    error("The data_path must be provided (path to the raw inputs)")
                }

                if (!meta.id) {
                    meta.id = file(data_path).baseName
                }

                meta.data_dir = data_path
            }
            else {
                // spaceranger output directory
                meta.data_dir = "outs"

                if (!meta.id) {
                    error("The id must be provided when running on Visium HD data")
                }

                if (!meta.image) {
                    error("The image (full resolution image) must be provided when running Sopa on Visium HD data - it is required for the cell segmentation")
                }
            }
            meta.sdata_dir = "${meta.id}.zarr"
            meta.explorer_dir = "${meta.id}.explorer"

            return meta
        }
        .map { samplesheet ->
            validateInputSamplesheet(samplesheet)
        }
        .set { ch_samplesheet }

    //
    // Sopa params validation
    //
    validateParams(params)

    emit:
    samplesheet = ch_samplesheet
    versions = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW FOR PIPELINE COMPLETION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_COMPLETION {
    take:
    email //  string: email address
    email_on_fail //  string: email address sent on pipeline failure
    plaintext_email // boolean: Send plain-text email instead of HTML
    outdir //    path: Path to output directory where results will be published
    monochrome_logs // boolean: Disable ANSI colour codes in log output
    hook_url //  string: hook URL for notifications

    main:
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")

    //
    // Completion email and summary
    //
    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
                [],
            )
        }

        completionSummary(monochrome_logs)
        if (hook_url) {
            imNotification(summary_params, hook_url)
        }
    }

    workflow.onError {
        log.error("Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting")
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Validate channels from input samplesheet
//
def validateInputSamplesheet(input) {
    return input
}
//
// Generate methods description for MultiQC
//
def toolCitationText() {
    def citation_text = [
        "Tools used in the workflow included:",
        "Sopa (Blampey et al. 2024),",
        "AnnData (Virshup et al. 2021),",
        "Scanpy (Wolf et al. 2018),",
        "Space Ranger (10x Genomics)",
        "SpatialData (Marconato et al. 2023) and",
    ].join(' ').trim()

    return citation_text
}

def toolBibliographyText() {
    def reference_text = [
        '<li>Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., & Notredame, C. (2017). Nextflow enables reproducible computational workflows. Nature Biotechnology, 35(4), 316-319. doi: <a href="https://doi.org/10.1038/nbt.3820">10.1038/nbt.3820</a></li>',
        '<li>Ewels, P. A., Peltzer, A., Fillinger, S., Patel, H., Alneberg, J., Wilm, A., Garcia, M. U., Di Tommaso, P., & Nahnsen, S. (2020). The nf-core framework for community-curated bioinformatics pipelines. Nature Biotechnology, 38(3), 276-278. doi: <a href="https://doi.org/10.1038/s41587-020-0439-x">10.1038/s41587-020-0439-x</a></li>',
        '<li>Grüning, B., Dale, R., Sjödin, A., Chapman, B. A., Rowe, J., Tomkins-Tinch, C. H., Valieris, R., Köster, J., & Bioconda Team. (2018). Bioconda: sustainable and comprehensive software distribution for the life sciences. Nature Methods, 15(7), 475–476. doi: <a href="https://doi.org/10.1038/s41592-018-0046-7">10.1038/s41592-018-0046-7</a></li>',
        '<li>da Veiga Leprevost, F., Grüning, B. A., Alves Aflitos, S., Röst, H. L., Uszkoreit, J., Barsnes, H., Vaudel, M., Moreno, P., Gatto, L., Weber, J., Bai, M., Jimenez, R. C., Sachsenberg, T., Pfeuffer, J., Vera Alvarez, R., Griss, J., Nesvizhskii, A. I., & Perez-Riverol, Y. (2017). BioContainers: an open-source and community-driven framework for software standardization. Bioinformatics (Oxford, England), 33(16), 2580–2582. doi: <a href="https://doi.org/10.1093/bioinformatics/btx192">10.1093/bioinformatics/btx192</a></li>',
        '<li>Quentin Blampey, Kevin Mulder, Margaux Gardet, Stergios Christodoulidis, Charles-Antoine Dutertre, Fabrice André, Florent Ginhoux & Paul-Henry Cournède. Sopa: a technology-invariant pipeline for analyses of image-based spatial omics. Nat Commun 2024 June 11. doi: <a href="https://dx.doi.org/10.1038/s41587-020-0439-x">10.1038/s41587-020-0439-x</a></li>',
        '<li>Virshup I, Rybakov S, Theis FJ, Angerer P, Wolf FA. bioRxiv 2021.12.16.473007. doi: <a href="https://doi.org/10.1101/2021.12.16.473007">10.1101/2021.12.16.473007</a></li>',
        '<li>Wolf F, Angerer P, Theis F. SCANPY: large-scale single-cell gene expression data analysis. Genome Biol 19, 15 (2018). doi: <a href="https://doi.org/10.1186/s13059-017-1382-0">10.1186/s13059-017-1382-0</a></li>',
        '<li>10x Genomics Space Ranger 2.1.0 [Online]: <a href="https://www.10xgenomics.com/support/software/space-ranger">10xgenomics.com/support/software/space-ranger</a></li>',
        '<li>Marconato L, Palla G, Yamauchi K, Virshup I, Heidari E, Treis T, Toth M, Shrestha R, Vöhringer H, Huber W, Gerstung M, Moore J, Theis F, Stegle O. SpatialData: an open and universal data framework for spatial omics. bioRxiv 2023.05.05.539647; doi:<a href="https://doi.org/10.1101/2023.05.05.539647"> 10.1101/2023.05.05.539647</a></li>',
    ].join(' ').trim()

    return reference_text
}

def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named map so can be used as with familiar NXF ${workflow} variable syntax in the MultiQC YML file
    def meta = [:]
    meta.workflow = workflow.toMap()
    meta["manifest_map"] = workflow.manifest.toMap()

    // Pipeline DOI
    if (meta.manifest_map.doi) {
        // Using a loop to handle multiple DOIs
        // Removing `https://doi.org/` to handle pipelines using DOIs vs DOI resolvers
        // Removing ` ` since the manifest.doi is a string and not a proper list
        def temp_doi_ref = ""
        def manifest_doi = meta.manifest_map.doi.tokenize(",")
        manifest_doi.each { doi_ref ->
            temp_doi_ref += "(doi: <a href=\'https://doi.org/${doi_ref.replace("https://doi.org/", "").replace(" ", "")}\'>${doi_ref.replace("https://doi.org/", "").replace(" ", "")}</a>), "
        }
        meta["doi_text"] = temp_doi_ref.substring(0, temp_doi_ref.length() - 2)
    }
    else {
        meta["doi_text"] = ""
    }
    meta["nodoi_text"] = meta.manifest_map.doi ? "" : "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

    // Tool references
    meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    meta["tool_bibliography"] = toolBibliographyText()


    def methods_text = mqc_methods_yaml.text

    def engine = new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}

def validateParams(params) {
    def TRANSCRIPT_BASED_METHODS = ['proseg', 'baysor', 'comseg']
    def STAINING_BASED_METHODS = ['stardist', 'cellpose']

    // top-level checks
    assert params.read instanceof Map && params.read.containsKey('technology') : "Provide a 'read.technology' key"
    assert params.containsKey('segmentation') : "Provide a 'segmentation' section"

    // backward compatibility
    TRANSCRIPT_BASED_METHODS.each { m ->
        if (params.segmentation?.get(m)?.containsKey('cell_key')) {
            println("Deprecated 'cell_key' → using 'prior_shapes_key' instead.")
            params.segmentation[m].prior_shapes_key = params.segmentation[m].cell_key
            params.segmentation[m].remove('cell_key')
        }
    }
    if (params.aggregate?.containsKey('average_intensities')) {
        println("Deprecated 'average_intensities' → using 'aggregate_channels' instead.")
        params.aggregate.aggregate_channels = params.aggregate.average_intensities
        params.aggregate.remove('average_intensities')
    }

    // check segmentation methods
    assert params.segmentation : "Provide at least one segmentation method"
    assert TRANSCRIPT_BASED_METHODS.count { params.segmentation.containsKey(it) } <= 1 : "Only one of ${TRANSCRIPT_BASED_METHODS} may be used"
    assert STAINING_BASED_METHODS.count { params.segmentation.containsKey(it) } <= 1 : "Only one of ${STAINING_BASED_METHODS} may be used"
    if (params.segmentation.containsKey('stardist')) {
        assert TRANSCRIPT_BASED_METHODS.every { !params.segmentation.containsKey(it) } : "'stardist' cannot be combined with transcript-based methods"
    }

    // check prior shapes key
    TRANSCRIPT_BASED_METHODS.each { m ->
        if (params.segmentation.containsKey(m) && params.segmentation.containsKey('cellpose')) {
            params.segmentation[m].prior_shapes_key = 'cellpose_boundaries'
        }
    }


    return params
}
