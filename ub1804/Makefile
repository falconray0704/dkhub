
.PHONY: all
all: dockerImg

#observer
.PHONY:dockerImg
dockerImg: clean
	docker build --rm -t rayruan/ub1804:basic \
				-f ./Dockerfile.img .
.PHONY:run
run:
	docker run --name ub1804 --rm -it --dns "192.168.11.1" --workdir=$$(pwd) --hostname "dc" -v $$(pwd):$$(pwd) rayruan/ub1804:basic

.PHONY: clean
clean:
	docker rmi -f rayruan/ub1804:basic
	docker image prune


