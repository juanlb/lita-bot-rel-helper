#!/bin/bash

ENV=$1
BRANCH=$2

# Environments
KEY_beta=dKrMRv7xwnBfymbCvEcBpcom6Wc=
KEY_production=nXFqaV0rdoieVFbp+NVvpbQh5O0=
KEY_demo=uOeEAEInRdFHghxyCOFKbxsKyz0=

# Execute

# Master
echo "Pulling from master..."
cd /home/ubuntu/bytelion/deploy/everseat-web
git checkout master
git pull

# Pull branch
echo ''
echo "Branch: $BRANCH"
echo ''
echo 'Git check out...'
git checkout $BRANCH
echo 'Git pull'
git pull

# bundle
KEY_ENV="KEY_$ENV"
KEY=${!KEY_ENV}

# push
ENV_DECRYPTION_KEY=$KEY bundle exec rake "docker:push[$ENV,ENV_DECRYPTION_KEY]" > /tmp/build_docker.log

tail -1 /tmp/build_docker.log > /tmp/build_result.log
