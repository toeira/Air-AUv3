#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
build_dir="${AIR_TEST_BUILD_DIR:-/tmp/air-dsp-build}"
mkdir -p "$build_dir"
inc=(-I Sources/DSP/Compat -I Sources/DSP/BlueLab -I Sources/DSP/WDL -I Sources/DSP)
cc -O1 -DWDL_FFT_REALSIZE=8 "${inc[@]}" -c Sources/DSP/WDL/fft.c -o "$build_dir/fft.o"
cc -O1 -DWDL_FFT_REALSIZE=8 "${inc[@]}" -c Sources/DSP/BlueLab/fast-dct-lee.c -o "$build_dir/dct.o"
c++ -std=c++17 -O1 -DWDL_FFT_REALSIZE=8 "${inc[@]}" Sources/DSP/BlueLab/*.cpp \
    Sources/DSP/AirEngine.cpp tests/dsp_smoke.cpp "$build_dir/fft.o" "$build_dir/dct.o" -o "$build_dir/test"
"$build_dir/test"
