
export ssRootDir=ssRoot
export buildDir=ssBuild

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

.PHONY:buildX86_64_StaticSS_Img
buildX86_64_StaticSS_Img:cleanX86_64_StaticSS_Img
	docker build --rm -t rayruan/alpine_x86_64:staticSS -f ./2.Build_StaticSS_Img ${PWD}/ssBuild/dist/x86_64/bin

.PHONY: cleanX86_64_StaticSS_Img
cleanX86_64_StaticSS_Img:
	docker rmi -f rayruan/alpine_x86_64:staticSS
	docker image prune
	
.PHONY:buildStaticSS
buildStaticSS:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		--entrypoint "/ssRoot/scripts/2.buildStaticSS.sh" \
		rayruan/ubt1604:ss-buildEnvStatic all 

.PHONY:runBuildEnvStatic
runBuildEnvStatic:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		rayruan/ubt1604:ss-buildEnvStatic

.PHONY:buildEnvStatic
buildEnvStatic:cleanBuildEnvStatic
	docker build --rm -t rayruan/ubt1604:ss-buildEnvStatic -f ./1.BuildEnvStatic .

.PHONY: cleanBuildEnvStatic
cleanBuildEnvStatic:
	docker rmi -f rayruan/ubt1604:ss-buildEnvStatic
	docker image prune


.PHONY:buildSS
buildSS:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		--entrypoint "/ssRoot/scripts/2.buildSS.sh" \
		rayruan/ubt1604:ss-buildEnv build 

.PHONY:runBuildEnv
runBuildEnv:
	mkdir -p ${buildDir}
	docker run --rm -it \
		--hostname "ssBuild" \
		-e buildDir \
		-v ${PWD}:/${ssRootDir} \
		rayruan/ubt1604:ss-buildEnv

#		-v ${PWD}/${buildDir}:/${ssRootDir}/${buildDir} \

.PHONY:buildEnv
buildEnv:cleanBuildEnv
	docker build --rm -t rayruan/ubt1604:ss-buildEnv -f ./1.BuildEnv .

.PHONY: cleanBuildEnv
cleanBuildEnv:
#	$(bash ./scripts/1.installBuildDeps.sh clean)
	docker rmi -f rayruan/ubt1604:ss-buildEnv
	docker image prune

