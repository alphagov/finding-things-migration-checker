#!/bin/bash

set -e

REPO="alphagov/finding-things-migration-checker"

VENV_PATH="${HOME}/venv/${JOB_NAME}"
[ -x ${VENV_PATH}/bin/pip ] || virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate
pip install -q ghtools

function github_status {
  repo="$1"
  git_commit="$2"
  status="$3"
  message="$4"
  build_url="$5"

  gh-status "${repo}" "${git_commit}" "${status}" -d "${message}" -u "${build_url}" >/dev/null
}

github_status "$REPO" "$GIT_COMMIT" pending "Build #${BUILD_NUMBER} is running on Jenkins" "$BUILD_URL"

if ./jenkins.sh; then
  github_status "$REPO" "$GIT_COMMIT" success "Build #${BUILD_NUMBER} succeeded on Jenkins" "$BUILD_URL"
  exit 0
else
  github_status "$REPO" "$GIT_COMMIT" failure "Build #${BUILD_NUMBER} failed on Jenkins" "$BUILD_URL"
  exit 1
fi
