#!/bin/bash

git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"

cd /this_project

if [ ! -d "/this_project/node_modules" ]; then
  cnpm install
fi

./ganache/start > ./docker/ganache.log &

truffle compile

truffle deploy --reset

npm run dev
