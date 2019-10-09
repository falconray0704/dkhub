
ARCH = $$(uname -m)

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: buildAll
buildAll:cleanAll img14 img16 img18

.PHONY: cleanAll
cleanAll:clean14 clean16 clean18
#observer

.PHONY:img14
img14: clean14
	docker build --rm -t rayruan/ubt1404_${ARCH}:basic -f ./Dockerfile1404.img .

.PHONY:img16
img16: clean16
	docker build --rm -t rayruan/ubt1604_${ARCH}:basic -f ./Dockerfile1604.img .

.PHONY:img18
img18: clean18
	docker build --rm -t rayruan/ubt1804_${ARCH}:basic -f ./Dockerfile1804.img .

.PHONY:run
run:
	docker run --name ub1804 --rm -it --dns "192.168.11.1" --workdir=$$(pwd) --hostname "dc" -v $$(pwd):$$(pwd) rayruan/ub1804:basic

.PHONY: clean14
clean14:
	docker rmi -f rayruan/ubt1404_${ARCH}:basic
	docker image prune

.PHONY: clean16
clean16:
	docker rmi -f rayruan/ubt1604_${ARCH}:basic
	docker image prune

.PHONY: clean18
clean18:
	docker rmi -f rayruan/ubt1804_${ARCH}:basic
	docker image prune

