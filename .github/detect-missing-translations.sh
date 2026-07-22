#!/bin/bash

# Extract all keys from English CSV files (first field, skip empty lines and header)
en_keys=$(grep -h "^[^,]" text/en/*.csv 2>/dev/null | grep -v "^\"keys\"" | cut -d',' -f1 | sed 's/"//g' | grep -v "^$" | sort -u)

# Get list of language directories (excluding en)
lang_dirs=$(find text/* -maxdepth 0 -type d ! -name en 2>/dev/null)

# Check each key in each language
for key in $en_keys; do
    for lang_dir in $lang_dirs; do
        lang=$(basename "$lang_dir")
        # Search for the key at the start of a line in CSV files (with or without quotes)
        if ! grep -h "^\"*$key\"*," "$lang_dir"/*.csv 2>/dev/null | grep -q .; then
            echo "Missing in $lang: $key"
        fi
    done
done
