#!/bin/bash

usage()
{
    echo "Usage: ./rtspServerRun.sh ./torystory.mp4"
}


[ $# -lt 1 ] && usage && exit

cvlc --repeat --sout '#rtp{sdp=rtsp://:5511/}' $1

