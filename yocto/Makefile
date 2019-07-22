
.PHONY: all
all:

#observer
.PHONY: basic
basic: cleanBasic
	docker build --rm -t rayruan/yocto:basic \
				-f ./DockerfileBasic.img .

.PHONY: build
build: cleanBuild
	cp -a ~/.vim ~/.vimrc ~/.vimrc.local ./
	docker build --rm -t rayruan/yocto:build \
				--build-arg "group=${USER}" \
				--build-arg "gid=$$(id -u)" \
				--build-arg "user=${USER}" \
				--build-arg	"uid=$$(id -g)" \
				-f ./DockerfileBuild.img .
	rm -rf ./.vim ./.vimrc ./.vimrc.local

.PHONY:run
run:
	docker run --name yotoBuild --rm -it --dns "192.168.11.1" --workdir=$$(pwd) --hostname "dc" -v $$(pwd):$$(pwd) rayruan/yocto:build

.PHONY: cleanBasic
cleanBasic:
	docker rmi -f rayruan/yocto:basic
	docker image prune

.PHONY: cleanBuild
cleanBuild:
	rm -rf ./.vim ./.vimrc ./.vimrc.local
	docker rmi -f rayruan/yocto:build
	docker image prune

