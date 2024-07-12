#!/bin/bash

JEKYLL_ENV=production  bundle exec jekyll build

rsync -crvz   _site/ ~/git-doc/
