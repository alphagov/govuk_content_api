#!/bin/bash

bundle install
bundle exec mr-sparkle --force-polling --pattern "rabl|rb|ru|txt|yml" -- -p 3022
