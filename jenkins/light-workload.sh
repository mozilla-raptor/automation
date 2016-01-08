#!/bin/sh -xe

cd gaia
pip install mutagen
make reference-workload-light
sleep 30
cd ..
