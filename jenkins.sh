#!/bin/bash -x

set -e

bundle install --path "${HOME}/bundles/${JOB_NAME}"
export GOVUK_APP_DOMAIN=dev.gov.uk
export GOVUK_ASSET_HOST=http://static.dev.gov.uk

USE_SIMPLECOV=true RACK_ENV=test bundle exec rake ci:setup:minitest test --trace
