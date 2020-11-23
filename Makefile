
PROJECT_NAME="bots-at-work"

TOOLS=tools
DIST=dist
WEBDIST=${DIST}/html5

GODOT_VERSION=3.2.3

GODOT=${HOME}/applis/godot/Godot_v3.2.1-stable_x11.64
GODOT_HEADLESS_BASE=Godot_v${GODOT_VERSION}-stable_linux_headless.64
GODOT_HEADLESS=${TOOLS}/${GODOT_HEADLESS_BASE}

SERVER_PCK=${DIST}/${PROJECT_NAME}-server.zip

SERVER=?kimsufi:research-severin/bots-at-work

all: linux

download-godot-headless: ${GODOT_HEADLESS}

${GODOT_HEADLESS}:
	mkdir -p ${TOOLS}
	wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/${GODOT_HEADLESS_BASE}.zip
	wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz
	unzip ${GODOT_HEADLESS_BASE}.zip
	unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz
	mv ${GODOT_HEADLESS_BASE} ${TOOLS}
	rm ${GODOT_HEADLESS_BASE}.zip


linux: ${GODOT_HEADLESS}
	mkdir -p ${DIST}
	${GODOT_HEADLESS} --export linux ${DIST}/${PROJECT_NAME}

run-standalone:
	${DIST}/${PROJECT_NAME} --standalone

run-server:
	${DIST}/${PROJECT_NAME} --server

run-client:
	${DIST}/${PROJECT_NAME} --client

web: ${GODOT_HEADLESS}
	mkdir -p ${WEBDIST}
	${GODOT_HEADLESS} --export HTML5 ${WEBDIST}/index.html

webserver: ${GODOT_HEADLESS}
	${GODOT_HEADLESS} --export-pack linux ${SERVER_PCK}

deploy-client: web
	scp ${WEBDIST}/* ${SERVER}

deploy-server: webserver
	scp ${SERVER_PCK} ${SERVER}

edit:
	${GODOT} project.godot

deploy: deploy-client deploy-server

clean:
	rm -rf dist/*
