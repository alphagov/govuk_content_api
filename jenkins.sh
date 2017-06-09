#!/bin/bash -x

set -e

bundle install --path "${HOME}/bundles/${JOB_NAME}"

export GOVUK_APP_DOMAIN=dev.gov.uk
export GOVUK_ASSET_HOST=http://static.dev.gov.uk
export USE_SIMPLECOV=true
export RACK_ENV=test

if [[ ${GIT_BRANCH} != "origin/master" ]]; then
  bundle exec govuk-lint-ruby \
    --diff \
    --format html --out rubocop-${GIT_COMMIT}.html \
    --format clang \
    config lib test
fi

bundle exec rake db:drop
