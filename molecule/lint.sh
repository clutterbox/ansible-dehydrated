#!/bin/bash
# accumulate error codes, allowing all linters to execute.
# exit with total of all error codes at end.

declare -i errors
catch() { errors=$errors+$?; }
trap catch ERR
onexit() { exit $errors; }
trap onexit EXIT

#set -x

yamllint .
ansible-lint
flake8
