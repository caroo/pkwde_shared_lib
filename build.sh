#!/bin/bash

source "$HOME/.rvm/scripts/rvm"
case $1 in
*)
  rvm ree-1.8.7-2011.03@pkwde_shared_lib
  bundle install --binstubs
  bundle exec rake test
  rvm 1.9.3-p0@pkwde_shared_lib_1_9
  bundle install
  bundle exec rake test
esac
