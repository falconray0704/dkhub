#
# Dockerfile for ffserver
#

FROM ubuntu:18.04

RUN apt-get update && apt-get install -y ffmpeg

COPY ffserver.conf /etc/

EXPOSE 554 8090

ENTRYPOINT ["ffserver"]
