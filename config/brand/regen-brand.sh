#!/usr/bin/env bash
# regen-brand.sh — rebuild CalTekNet brand assets from source.
# Requires: python3, pip packages cairosvg, pillow, numpy, scipy
set -euo pipefail
cd "$(dirname "$0")"

echo "[1/2] generating phi master + derivatives..."
python3 gen_phi.py            # emits caltek-phi.svg (color master)

echo "[2/2] rasterizing PNGs..."
python3 - <<'PY'
import cairosvg
for n in ["caltek-phi","caltek-phi-grayscale","caltek-phi-bw"]:
    try:
        cairosvg.svg2png(url=f"{n}.svg", write_to=f"{n}.png",
                         output_width=600, output_height=670)
        print("  ok:", n)
    except FileNotFoundError:
        print("  skip (missing):", n)
PY
echo "done. commit *.svg (source of truth) + gen_phi.py; PNGs are build artifacts."
