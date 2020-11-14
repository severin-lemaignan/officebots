
PROJECT_NAME="bots-at-work"

DIST=dist
WEBDIST=${DIST}/html5

GODOT=${HOME}/applis/godot/Godot_v3.2.1-stable_x11.64

SERVER_PCK=${DIST}/${PROJECT_NAME}-server.zip

SERVER=?kimsufi:research-severin/bots-at-work

all: linux

linux:
	mkdir -p ${DIST}
	${GODOT} --export linux ${DIST}/${PROJECT_NAME}

run-server:
	${DIST}/${PROJECT_NAME} --server

run-client:
	${DIST}/${PROJECT_NAME} --client

web:
	mkdir -p ${WEBDIST}
	${GODOT} --export HTML5 ${WEBDIST}/index.html

webserver:
	${GODOT} --export-pack linux ${SERVER_PCK}

deploy-client: web
	scp ${WEBDIST}/* ${SERVER}

deploy-server: webserver
	scp ${SERVER_PCK} ${SERVER}

deploy: deploy-client deploy-server

clean:
	rm -rf dist/*
