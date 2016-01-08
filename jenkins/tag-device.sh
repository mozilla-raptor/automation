#!/bin/bash -e

${ADB} shell setprop persist.raptor.memory ${MEMORY}
${ADB} shell setprop persist.raptor.device ${DEVICE_TYPE}
${ADB} shell setprop persist.raptor.branch ${BRANCH}
