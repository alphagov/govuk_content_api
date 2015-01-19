#!/bin/bash

bundle install
bundle exec mr-sparkle --force-polling --pattern "rb|ru|txt|yml" -- -p 3022
