#!/usr/bin/env bash
# Clean and pad a Base64 file in place
# Useful when having issues with credentials export/import "b64" sign
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input-file> [output-file]" >&2
  echo "Example: $0 exported-systemcrede.txt fixed-systemcrede.txt" >&2
  exit 1
fi

infile="$1"
outfile="${2:-$infile}"

# Create temporary file
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Remove CR/LF and keep only Base64 chars
tr -d '\r\n' <"$infile" | grep -o '[A-Za-z0-9+/=]' | tr -d '\n' >"$tmp"

# Compute length mod 4 and pad with '=' if needed
len=$(wc -c <"$tmp")
mod=$((len % 4))
if [ "$mod" -eq 2 ]; then
  printf '==' >> "$tmp"
elif [ "$mod" -eq 3 ]; then
  printf '=' >> "$tmp"
elif [ "$mod" -eq 1 ]; then
  echo "Error: Base64 data length mod 4 == 1 (invalid)" >&2
  exit 1
fi

# Overwrite or write output
mv "$tmp" "$outfile"
echo "Cleaned and padded Base64 written to $outfile"