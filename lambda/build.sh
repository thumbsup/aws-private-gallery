#!/bin/bash -e

echo ''
echo '---------------------------'
echo 'Building: cloudfront-cookies'
echo '---------------------------'
echo ''

(cd login && docker build -t "cloudfront-cookies" .)
docker run "cloudfront-cookies" > login.zip

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
