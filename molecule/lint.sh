#!/bin/bash
# accumulate error codes, allowing all linters to execute.
# exit with total of all error codes at end.

declare -i errors
catch() { errors=$errors+$?; }
trap catch ERR
onexit() { exit $errors; }
trap onexit EXIT

#set -e

yamllint .

# adding "." to avoid warning over expectation of playbook.yml
# ansible-lint
ansible-lint .

# explictly run on molecule playbooks, skipped otherwise
ansible-lint molecule/*/*.yml

flake8
