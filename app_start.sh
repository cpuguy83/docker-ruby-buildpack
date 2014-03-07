#!/bin/bash
source /usr/local/rvm/scripts/rvm
rvm use ruby
exec /tmp/app_setup.rb "${@}"
