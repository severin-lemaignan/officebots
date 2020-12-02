
PROJECT_NAME=officebots

TOOLS=tools
DIST=dist
WEBDIST=${DIST}/html5

GODOT_VERSION=3.2.3

GODOT=${HOME}/applis/godot/Godot_v${GODOT_VERSION}-stable_x11.64
GODOT_HEADLESS_BASE=Godot_v${GODOT_VERSION}-stable_linux_headless.64
#GODOT_HEADLESS=${TOOLS}/${GODOT_HEADLESS_BASE}
GODOT_HEADLESS=${GODOT}

TEMPLATES_ROOT?=$(shell pwd)/${TOOLS}

SERVER_PCK=${DIST}/${PROJECT_NAME}-server.zip

SERVER=kimsufi:research-severin/bots-at-work

SOURCES := $(wildcard *.gd) $(wildcard *.tscn)

# .PHONY means these rules get executed even if
# files of those names exist.
.PHONY: all clean

all: linux

download-godot-headless: ${GODOT_HEADLESS}

Godot_v${GODOT_VERSION}-stable_export_templates.tpz:
	mkdir -p ${TOOLS}/godot/templates/${GODOT_VERSION}.stable
	wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz
	unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz
	mv templates/* ${TOOLS}/godot/templates/${GODOT_VERSION}.stable/
	rmdir templates

${GODOT_HEADLESS_BASE}.zip:
	mkdir -p ${TOOLS}
	wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/${GODOT_HEADLESS_BASE}.zip
	unzip ${GODOT_HEADLESS_BASE}.zip
	mv ${GODOT_HEADLESS_BASE} ${TOOLS}

${GODOT_HEADLESS}: Godot_v${GODOT_VERSION}-stable_export_templates.tpz ${GODOT_HEADLESS_BASE}.zip


linux: ${GODOT_HEADLESS} ${DIST}/${PROJECT_NAME}

${DIST}/${PROJECT_NAME}: $(SOURCES)
	mkdir -p ${DIST}
	XDG_DATA_HOME=${TEMPLATES_ROOT} ${GODOT_HEADLESS} --export linux ${DIST}/${PROJECT_NAME}

run-standalone:
	${DIST}/${PROJECT_NAME} --standalone

run-server:
	${DIST}/${PROJECT_NAME} --server

run-client:
	${DIST}/${PROJECT_NAME} --client

web: ${GODOT_HEADLESS} ${WEBDIST}/index.wasm

${WEBDIST}/index.wasm: $(SOURCES)
	mkdir -p ${WEBDIST}
	${GODOT_HEADLESS} --export HTML5 ${WEBDIST}/index.html

${SERVER_PCK}: $(SOURCES)
	${GODOT_HEADLESS} --export-pack linux ${SERVER_PCK}

webserver: ${GODOT_HEADLESS} ${SERVER_PCK}

deploy-client: web
	scp ${WEBDIST}/* ${SERVER}

deploy-server: webserver
	scp ${SERVER_PCK} ${SERVER}

edit:
	${GODOT} project.godot

deploy: deploy-client deploy-server

clean:
	rm -rf dist/*
