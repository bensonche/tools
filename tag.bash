#!/bin/bash

git tag -a Release_3.6.$1 -m "Release 3.6.$1" &&
git push origin Release_3.6.$1