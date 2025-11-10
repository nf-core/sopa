#!/bin/bash

# Copyright (c) The nf-core/sopa team
#
# Convert all YAML config files in subdirectories to Nextflow config files
# Needs to set the SOPA_DIR environment variable to the repository root

if [ -z "${SOPA_DIR:-}" ]; then
    echo "Error: SOPA_DIR environment variable is not set. Please clone https://github.com/gustaveroussy/sopa.git and set SOPA_DIR to the repository root." >&2
    exit 1
fi

find "$SOPA_DIR/workflow/config" -mindepth 2 -maxdepth 2 -type f -name '*.yaml' | while read -r file; do
    parent_dir=$(basename "$(dirname "$file")")
    filename=$(basename "$file")
    name_no_suffix="${filename%.*}"
    output_file="${parent_dir}_${name_no_suffix}.config"

    nextflow run convert.nf -params-file "$file" --output "$output_file"
    echo "$output_file generated."
done
