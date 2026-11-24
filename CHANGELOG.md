# nf-core/sopa: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.2 - [2026-10-03]

### Added

- Add process to download pretrained models by @alihamraoui in https://github.com/nf-core/sopa/pull/37
- Add GPU support for Cellpose by @alihamraoui in https://github.com/nf-core/sopa/pull/39
- Add a parameter to pass kwargs to the sopa reader by @quentinblampey in https://github.com/nf-core/sopa/pull/43

### Updated

- Updated all containers - including baysor (using the baysor-cpp bioconda recipe) by @alihamraoui in https://github.com/nf-core/sopa/pull/45
- Update sopa to 2.2.11 and rebuild the Wave conainers by @alihamraoui in https://github.com/nf-core/sopa/pull/36

### Minor updates

- validation of segmentation method combinations by @alihamraoui in https://github.com/nf-core/sopa/pull/38
- Switch fix-linting to the hardened nf-core/actions reusable workflow by @mashehu in https://github.com/nf-core/sopa/pull/40
- Move seqeralabs/action-tower-launch to @v2 (v2.4.0) by @mashehu in https://github.com/nf-core/sopa/pull/41
- pin scanpy to v1.12.4 by @alihamraoui in https://github.com/nf-core/sopa/pull/47
- Template update for nf-core/tools v4.2.1 by @nf-core-bot in https://github.com/nf-core/sopa/pull/44

## v1.0.1 - [2026-08-25]

### Fixes

- Fix: set writable env vars for StarDist and Proseg segmentation (#35)
- Ensure the tests can't silently fail (#29)

### Updates

- Support the `image_scale` parameter (#30)
- Update the spaceranger module (#28)
- Template update for nf-core/tools v4.0.2 (#23)

## v1.0.0 - [2026-07-15]

Initial release of nf-core/sopa, created with the [nf-core](https://nf-co.re/) template.
