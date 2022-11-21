#!/usr/bin/env bash

set -e

git checkout master
git pull

git checkout pc
git rebase master
git push -f

git checkout laptop
git rebase master
git push -f

git checkout laptop-personal
git rebase laptop
git push -f

git checkout work
git rebase laptop
git push -f

git checkout master
