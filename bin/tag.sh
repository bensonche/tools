#!/bin/bash

git tag -a Release_4.5.$1 -m "Release 4.5.$1" &&
git push origin Release_4.5.$1
