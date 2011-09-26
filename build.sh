#!/bin/bash

source "$HOME/.rvm/scripts/rvm"
case $1 in
*)
  rvm ree@pkwde_shared_lib
  bundle install --binstubs
  bundle exec rake test
esac
