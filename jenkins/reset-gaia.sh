#!/bin/sh -xe

cd gaia
make raptor

${ADB} wait-for-device 
${ADB} shell 'i=1;
retries=60
while [ "$(getprop sys.boot_completed)" == "1" ]; do
  if (( i++ > ($retries - 1) )); then
    exit 1;
  fi;
  sleep 1;
done'

sleep 30
cd ..
