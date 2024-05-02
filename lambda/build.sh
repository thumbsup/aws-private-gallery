#!/bin/bash -e

echo ''
echo '---------------------------'
echo 'Building: cloudfront-cookies'
echo '---------------------------'
echo ''

(cd login && docker build -t "cloudfront-cookies" .)
container_id=$(docker create cloudfront-cookies)
docker cp $container_id:/build/dist.zip login.zip
docker rm $container_id

echo ''
echo '---------------------------'
echo 'Building: cognito-whitelist'
echo '---------------------------'
echo ''

(cd whitelist && zip -r ../whitelist.zip .)

echo ''
echo '--------------------------------------'
echo 'Successfully packaged lambda functions'
echo '--------------------------------------'
echo ''
