
export ssRootDir=ssRoot
export buildDir=ssBuild
LOCAL_ARCH := $(shell arch)

.PHONY: all
all:

.PHONY: run
run:

.PHONY: clean
clean:

.PHONY: deploySrv
deploySrv:
	rm -rf ~/ssSrv
	cp -a ./setup/srv ~/ssSrv
	docker rmi -f rayruan/alpine:staticSS
	docker pull rayruan/alpine:staticSS

.PHONY:buildImgStaticSS
buildImgStaticSS:cleanImgStaticSS
	docker build --rm -t rayruan/alpine:staticSS -f ./2.BuildImgStaticSS ${PWD}/ssBuild/dist/${LOCAL_ARCH}/bin

.PHONY: cleanImgStaticSS
cleanImgStaticSS:
	docker rmi -f rayruan/alpine:staticSS
	docker image prune
	
.PHONY:buildStaticSS
buildStaticSS:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		--entrypoint "/ssRoot/scripts/2.buildStaticSS.sh" \
		rayruan/ubt1604:ssBuilderStatic ${LOCAL_ARCH} 

.PHONY:runBuilderStatic
runBuilderStatic:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		rayruan/ubt1604:ssBuilderStatic

.PHONY:builderStatic
builderStatic:cleanBuilderStatic
	docker build --rm -t rayruan/ubt1604:ssBuilderStatic -f ./1.builderStatic .

.PHONY: cleanBuilderStatic
cleanBuilderStatic:
	docker rmi -f rayruan/ubt1604:ssBuilderStatic
	docker image prune


.PHONY:buildSS
buildSS:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		--entrypoint "/ssRoot/scripts/2.buildSS.sh" \
		rayruan/ubt1604:ssBuilder build 

.PHONY:runBuilder
runBuilder:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		rayruan/ubt1604:ssBuilder

#		-v ${PWD}/${buildDir}:/${ssRootDir}/${buildDir} \

.PHONY:builder
builder:cleanBuilder
	docker build --rm -t rayruan/ubt1604:ssBuilder -f ./1.builder .

.PHONY: cleanBuilder
cleanBuilder:
#	$(bash ./scripts/1.installBuildDeps.sh clean)
	docker rmi -f rayruan/ubt1604:ssBuilder
	docker image prune

