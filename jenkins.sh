#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}"

USE_SIMPLECOV=true RACK_ENV=test bundle exec rake ci:setup:testunit test --trace
