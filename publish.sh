#!/bin/bash

FFPMEG_VERSION=4.1.3
LAYER_NAME='ffmpeg'

REGIONS='
eu-west-1
'
PROFILE='dev'

for region in $REGIONS; do
  aws lambda add-layer-version-permission --region $region --layer-name $LAYER_NAME \
    --statement-id sid1 --action lambda:GetLayerVersion --principal '*' \
    --version-number $(aws lambda publish-layer-version --region $region --layer-name $LAYER_NAME --zip-file fileb://layer.zip \
      --description "FFMPEG ${GIT_VERSION} binaries" --query Version --output text --profile $PROFILE) --profile $PROFILE
done
