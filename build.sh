#!/bin/sh

export FFMPEG_VERSION=4.1.3

docker build --build-arg FFMPEG_VERSION -t ffmpeg-lambda-layer .
docker run --rm ffmpeg-lambda-layer cat /tmp/ffmpeg-${FFMPEG_VERSION}.zip > ./layer.zip
