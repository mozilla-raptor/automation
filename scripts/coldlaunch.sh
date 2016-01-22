#!/bin/bash -x

# receive list of apps to run coldlaunch test against
# i.e. 'calendar clock communications@dialer email'
APP_LIST=$1
JOB_TIME=$(node -e "console.log(Date.now());")

post_to_treeherder() {
  local RAPTOR_BUILD_STATE=$1
  local RAPTOR_APP_NAME=$2
  local TEST_START_TIME=$3
  local TEST_FINISH_TIME=$4
  local TEST_FAILURE=$5

  python --version
  source raptor-env/bin/activate
  python --version

  TEST_TIME="${JOB_TIME}" post-to-treeherder/submit-to-treeherder.py \
    --repository b2g-inbound \
    --build-state ${RAPTOR_BUILD_STATE} \
    --treeherder-url https://treeherder.allizom.org/ \
    --treeherder-client-id raptor \
    --treeherder-secret ${RAPTOR_TREEHERDER_SECRET} \
    --test-type cold-launch \
    --app-name ${RAPTOR_APP_NAME} \
    --start-time ${TEST_START_TIME} \
    --finish-time ${TEST_FINISH_TIME} \
    --test-failure ${TEST_FAILURE}
}

run_coldlaunch_test() {
  local APP_ORIGIN=$1
  local ENTRY_POINT=$2

  APP_FAILURE=0

  local FILE_FORMAT="${APP_ORIGIN}"
  local ENTRY_FLAG=""

  # run coldlaunch
  if [ -n "$ENTRY_POINT" ] ; then
    local FILE_FORMAT="${APP_ORIGIN}-${ENTRY_POINT}"
    local ENTRY_FLAG="--entry-point ${ENTRY_POINT}"
  fi

  if [ -n "$RAPTOR_DATABASE_NAME" ] ; then
    local DATABASE_FLAG="--database ${RAPTOR_DATABASE_NAME}"
  fi

  DEBUG=* ${PWD}/node_modules/.bin/raptor test coldlaunch \
    --serial ${ANDROID_SERIAL} \
    --app ${APP_ORIGIN} \
    --runs ${RUNS} \
    --timeout ${TIMEOUT} \
    --time ${JOB_TIME} \
    --metrics ${FILE_FORMAT}.ldjson \
    --logcat ${FILE_FORMAT}.logcat \
    ${ENTRY_FLAG} 2>&1 | tee ${FILE_FORMAT}.log

  APP_FAILURE=${PIPESTATUS[0]}

  local LINES="$(wc -l < ${FILE_FORMAT}.ldjson)"
  local EXPECTED="$((RUNS + 1))"

  # submit results to db
  if [[ ${LINES} -eq ${EXPECTED} ]] && [[ ${APP_FAILURE} == 0 ]] ; then
    DEBUG=* ${PWD}/node_modules/.bin/raptor submit ${FILE_FORMAT}.ldjson \
      --host ${RAPTOR_HOST} \
      --port ${RAPTOR_PORT} \
      --username ${RAPTOR_USERNAME} \
      --password ${RAPTOR_PASSWORD} \
      --protocol ${RAPTOR_PROTOCOL} \
      ${DATABASE_FLAG}
  else
    APP_FAILURE=1
    SUITE_FAILURE=1
  fi
}

# main coldlaunch loop
SUITE_FAILURE=0
APP_FAILURE=0

for i in ${APP_LIST[@]}
do
  APP=${i}

  # origin@entrypoint
  if [[ "${APP}" =~ "@" ]] ; then
    ORIGIN=${APP%@*}
    ENTRY=${APP#*@}
  else
    ORIGIN=${APP}
    ENTRY=''
  fi

  APP_START_TIME=$(node -e "console.log(Date.now());")
  post_to_treeherder running ${APP} ${APP_START_TIME}

  run_coldlaunch_test ${ORIGIN} ${ENTRY}

  APP_FINISH_TIME=$(node -e "console.log(Date.now());")
  post_to_treeherder completed ${APP} ${APP_START_TIME} ${APP_FINISH_TIME} ${APP_FAILURE}
done

exit ${SUITE_FAILURE}
