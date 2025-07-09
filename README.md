<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-sopa_logo_dark.png">
    <img alt="nf-core/sopa" src="docs/images/nf-core-sopa_logo_light.png">
  </picture>
</h1>[![GitHub Actions CI Status](https://github.com/nf-core/sopa/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/sopa/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/sopa/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/sopa/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/sopa/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/sopa)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23sopa-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/sopa)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/sopa** is the Nextflow version of [Sopa](https://github.com/gustaveroussy/sopa). Built on top of [SpatialData](https://github.com/scverse/spatialdata), Sopa enables processing and analyses of spatial omics data with single-cell resolution (spatial transcriptomics or multiplex imaging data) using a standard data structure and output. We currently support the following technologies: Xenium, Visium HD, MERSCOPE, CosMX, PhenoCycler, MACSima, Molecural Cartography, and others. It outputs a `.zarr` directory containing a processed [SpatialData](https://github.com/scverse/spatialdata) object, and a `.explorer` directory for visualization.

<p align="center">
  <img src="https://raw.githubusercontent.com/gustaveroussy/sopa/main/docs/assets/overview_white.png" alt="sopa_overview" width="100%"/>
</p>

<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet that lists the `data_path` to each sample data directory (typically, the per-sample output of the Xenium/MERSCOPE/etc, see more info [here](https://gustaveroussy.github.io/sopa/faq/#what-are-the-inputs-or-sopa)). You can optionally add `sample` to provide a name to your output directory, else it will be named based on `data_path`. Here is a samplesheet example:

`samplesheet.csv`:

```csv
sample,data_path
SAMPLE1,/path/to/one/merscope_directory
SAMPLE2,/path/to/one/merscope_directory
```

Then, choose a Sopa config file. You can find existing Sopa config files [here](https://github.com/gustaveroussy/sopa/tree/main/workflow/config). Follow the README instructions of the latter link to get your `--configfile`.

Now, you can run the pipeline using:

```bash
nextflow run nf-core/sopa \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --configfile <CONFIGFILE> \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/sopa/usage) and the [parameter documentation](https://nf-co.re/sopa/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/sopa/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/sopa/output).

## Credits

nf-core/sopa was originally written by Quentin Blampey.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#sopa` channel](https://nfcore.slack.com/channels/sopa) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/sopa for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) --><!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `sopa` publication as follows:

```txt
@article{blampey_sopa_2024,
	title = {Sopa: a technology-invariant pipeline for analyses of image-based spatial omics},
	volume = {15},
	url = {https://www.nature.com/articles/s41467-024-48981-z},
	doi = {10.1038/s41467-024-48981-z},
	journal = {Nature Communications},
	author = {Blampey, Quentin and Mulder, Kevin and Gardet, Margaux and Christodoulidis, Stergios and Dutertre, Charles-Antoine and André, Fabrice and Ginhoux, Florent and Cournède, Paul-Henry},
	year = {2024},
	note = {Publisher: Nature Publishing Group},
	pages = {4981},
}
```

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
