#!/bin/sh -xe

cd ${PWD}/gaia
pip install mutagen
make reference-workload-light
sleep 30
cd -
