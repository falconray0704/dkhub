
# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

.PHONY: all
all:vlc

#observer

.PHONY:vlc
vlc: vlc
	docker build --rm -t rayruan/deb-slim:vlc -f ./DockerfileAll.img .

.PHONY:installvlc
installvlc: cleaninstallvlc
	docker build --rm -t rayruan/deb-slim:install-vlc -f ./DockerfileInstall.img .

.PHONY:runvlc
runvlc: cleanrunvlc
	docker build --rm -t rayruan/deb-slim:run-vlc -f ./DockerfileRun.img .

.PHONY:rtspSrv
rtspSrv: cleanrtspSrv
	docker build --rm -t rayruan/deb-slim:vlc-rtspSrv -f ./DockerfileRtspServer.img .

.PHONY:run
run:
	docker run --rm \
		-v ${HOME}:/home/vlc \
		-v /tmp/.X11-unix/:/tmp/.X11-unix/ \
		-v /dev/snd:/dev/snd \
		-v /dev/shm:/dev/shm \
		-v /var/run/dbus:/var/run/dbus \
		-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
		-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
		--group-add $$(getent group audio | cut -d: -f3) \
		-e DISPLAY rayruan/deb-slim:run-vlc

.PHONY:runBash
runBash:
	docker run --rm -it \
		-v ${HOME}:/home/vlc \
		-v /tmp/.X11-unix/:/tmp/.X11-unix/ \
		-v /dev/snd:/dev/snd \
		-v /dev/shm:/dev/shm \
		-v /var/run/dbus:/var/run/dbus \
		-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
		-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
		--group-add $$(getent group audio | cut -d: -f3) \
		--entrypoint "/bin/bash" \
		-e DISPLAY rayruan/deb-slim:run-vlc

.PHONY:runRtspSrv
runRtspSrv:
	docker run --rm -it \
		--hostname "rtspSrv" \
		--workdir="/rtspSrv" \
		-v ${HOME}:/home/vlc \
		-v /tmp/.X11-unix/:/tmp/.X11-unix/ \
		-v /dev/snd:/dev/snd \
		-v /dev/shm:/dev/shm \
		-v /var/run/dbus:/var/run/dbus \
		-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
		-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
		--group-add $$(getent group audio | cut -d: -f3) \
		-e DISPLAY rayruan/deb-slim:vlc-rtspSrv

.PHONY: clean
clean:cleanvlc

.PHONY: cleanvlc
cleanvlc:
	docker rmi -f rayruan/deb-slim:vlc
	docker image prune

.PHONY: cleaninstallvlc
cleaninstallvlc:
	docker rmi -f rayruan/deb-slim:install-vlc
	docker image prune

.PHONY: cleanrunvlc
cleanrunvlc:
	docker rmi -f rayruan/deb-slim:run-vlc
	docker image prune

.PHONY: cleanrtspSrv
cleanrtspSrv:
	docker rmi -f rayruan/deb-slim:vlc-rtspSrv
	docker image prune
