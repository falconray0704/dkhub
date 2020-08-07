ffserver - FFserver video server
================================

![](https://badge.imagelayers.io/vimagick/ffserver:latest.svg)

[FFserver][1] is a streaming server for both audio and video. It supports
several live feeds, streaming from files and time shifting on live
feeds (you can seek to positions in the past on each live feed,
provided you specify a big enough feed storage in `ffserver.conf`).

## docker-compose.yml

```yaml
ffserver:
  image: vimagick/ffserver
  ports:
    - "554:554"
    - "8090:8090"
  volumes:
    - ./ffserver.conf:/etc/ffserver.conf
    - ./data:/data
  restart: always
```

## ffserver.conf

```
HTTPPort 8090
HTTPBindAddress 0.0.0.0

RTSPPort 554
RTSPBindAddress 0.0.0.0

MaxClients 100
MaxBandwidth 100000
CustomLog -

<Feed feed.ffm>
File /data/feed.ffm
</Feed>

<Stream video.mp4>
Format rtp
Feed feed.ffm
VideoCodec libx264
VideoFrameRate 24
VideoBitRate 100
VideoSize 640x480
AVPresetVideo default
AVPresetVideo baseline
AVOptionVideo flags +global_header
NoAudio
#AudioCodec libmp3lame
#AudioBitRate 32
#AudioChannels 2
#AudioSampleRate 22050
#AVOptionAudio flags +global_header
</Stream>

<Stream status.html>
Format status
</Stream>
```

> :warning: I've not figured out how to stream video+audio yet!

## Server Setup

```bash
$ cd ~/fig/ffserver
$ tree
.
├── data
│   └── video.mp4
├── docker-compose.yml
└── ffserver.conf

$ docker-compose up -d
$ docker-compose exec ffserver ffmpeg -re -i video.mp4 http://localhost:8090/feed.ffm
```

> :hammer: `data/video.mp4` is for testing purposes only.

## Client Setup

```bash
# Pushing file
$ ffmpeg -re -i video.mp4 http://easypi.info:8090/feed.ffm

# Pushing usb camera yuyv422
ffmpeg -f v4l2 -input_format yuyv422 -framerate 30 -video_size 640x480 -i /dev/video0 -c:v nvenc -vf format=yuv420p -an http://192.168.11.158:8090/camfeed.ffm

# Pushing usb camera mjpg
ffmpeg -f v4l2 -input_format mjpeg -framerate 30 -video_size 1920x1080 -i /dev/video2 -c:v nvenc -vf format=yuv420p -an http://192.168.11.158:8090/camfeed1920x1080.ffm

```

## Player Setup

```bash
$ ffplay rtsp://192.168.11.158:554/usbcam1920x1080.mov
$ ffplay rtsp://easypi.info/video.mp4
$ vlc http://easypi.info:8090/video.rtsp
$ firefox http://easypi.info:8090/status.html
```

## References

- <http://ffmpeg.org/ffserver.html>
- <http://www.ffmpeg.org/sample.html>
- <https://trac.ffmpeg.org/wiki/ffserver>

[1]: https://www.ffmpeg.org/ffserver.html
