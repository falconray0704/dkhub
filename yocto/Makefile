
.PHONY: all
all:

#observer
.PHONY: basic18
basic18: cleanBasic18
	docker build --rm -t rayruan/yocto:basic1804 -f ./DockerfileBasic1804.img .

.PHONY: basic16
basic16: cleanBasic16
	docker build --rm -t rayruan/yocto:basic1604 -f ./DockerfileBasic1604.img .

.PHONY: basic14
basic14: cleanBasic14
	docker build --rm -t rayruan/yocto:basic1404 -f ./DockerfileBasic1404.img .

.PHONY: build18
build18: cleanBuild18
	docker build --rm -t rayruan/yocto:build1804 \
				--build-arg "group=${USER}" \
				--build-arg "gid=$$(id -u)" \
				--build-arg "user=${USER}" \
				--build-arg	"uid=$$(id -g)" \
				-f ./DockerfileBuild1804.img .

.PHONY: build16
build16: cleanBuild16
	docker build --rm -t rayruan/yocto:build1604 \
				--build-arg "group=${USER}" \
				--build-arg "gid=$$(id -u)" \
				--build-arg "user=${USER}" \
				--build-arg	"uid=$$(id -g)" \
				-f ./DockerfileBuild1604.img .

.PHONY: build14
build14: cleanBuild14
	docker build --rm -t rayruan/yocto:build1404 \
				--build-arg "group=${USER}" \
				--build-arg "gid=$$(id -u)" \
				--build-arg "user=${USER}" \
				--build-arg	"uid=$$(id -g)" \
				-f ./DockerfileBuild1404.img .

.PHONY:run
run:
	docker run --name yotoBuild --rm -it --dns "192.168.11.1" --workdir=$$(pwd) --hostname "dc" -v $$(pwd):$$(pwd) rayruan/yocto:build

.PHONY: cleanBasic14
cleanBasic14:
	docker rmi -f rayruan/yocto:basic1404
	docker image prune

.PHONY: cleanBasic16
cleanBasic16:
	docker rmi -f rayruan/yocto:basic1604
	docker image prune

.PHONY: cleanBasic18
cleanBasic18:
	docker rmi -f rayruan/yocto:basic1804
	docker image prune

.PHONY: cleanBuild14
cleanBuild14:
	docker rmi -f rayruan/yocto:build1404
	docker image prune

.PHONY: cleanBuild16
cleanBuild16:
	docker rmi -f rayruan/yocto:build1604
	docker image prune

.PHONY: cleanBuild18
cleanBuild18:
	docker rmi -f rayruan/yocto:build1804
	docker image prune

