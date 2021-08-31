
PROJECT_NAME=officebots

TOOLS=tools
DIST=dist
WEBDIST=${DIST}/html5

GODOT_VERSION=3.3.3

GODOT=${HOME}/applis/godot/Godot_v${GODOT_VERSION}-stable_x11.64
GODOT_HEADLESS_BASE=Godot_v${GODOT_VERSION}-stable_linux_headless.64
#GODOT_HEADLESS=${TOOLS}/${GODOT_HEADLESS_BASE}
GODOT_HEADLESS=${GODOT}

TEMPLATES_ROOT?=$(shell pwd)/${TOOLS}

SERVER_PCK=${DIST}/${PROJECT_NAME}-server.zip

SERVER=kimsufi:research-severin/bots-at-work

REMOTE_SERVER_URL=https://officebots.skadge.org
REMOTE_SERVER_PORT=6969

SOURCES := $(wildcard *.gd) $(wildcard *.tscn)

RANDNAME:=$(shell python -c 'from random import choice; print(choice(["Tommy","Nisha","Eshal","Giselle","Kyal","Aditya","Isl","Matteo","Santiago","Keeleigh","Maggie","Arya","Evelyn","Ammara","Harry","Bianka","Amna","Shiloh","Omari","Lilah","Yusef","Sabiha","Suhail","Arla","Remy","Umaima","Cohen","Elsie","Dominick","Kamila","Maheen","Terrell","Oakley","Kishan","Amit","Britany","Beatriz","Katharine","Rehaan","Clayton","Tala","Ibraheem","Mazie","Clare","Velma","Kim","Honor","Shabaz","Jan","Moesha","Mindy"]));')

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
	@echo -en "\033]0;Officebot standalone\a"
	${DIST}/${PROJECT_NAME} --standalone
	@echo -en "\033]0;Terminal\a"

run-server:
	@echo -en "\033]0;Officebot local server\a"
	${DIST}/${PROJECT_NAME} --server
	@echo -en "\033]0;Terminal\a"

run-client:
	@echo -en "\033]0;Officebot client '$(RANDNAME)' - localhost\a"
	${DIST}/${PROJECT_NAME} --client --name=$(RANDNAME)
	@echo -en "\033]0;Terminal\a"

run-client-remote:
	@echo -en "\033]0;Officebot client '$(RANDNAME)' - $(REMOTE_SERVER_URL)\a"
	${DIST}/${PROJECT_NAME} --client --name=$(RANDNAME) --server=$(REMOTE_SERVER_URL) --port=$(REMOTE_SERVER_PORT)
	@echo -en "\033]0;Terminal\a"

web: ${GODOT_HEADLESS} ${WEBDIST}/index.wasm

${WEBDIST}/index.wasm: $(SOURCES)
	mkdir -p ${WEBDIST}
	${GODOT_HEADLESS} --export HTML5 ${WEBDIST}/index.html

${SERVER_PCK}: $(SOURCES)
	${GODOT_HEADLESS} --export-pack linux ${SERVER_PCK}

webserver: ${GODOT_HEADLESS} ${SERVER_PCK}

deploy-client: web
	@echo -en "\033]0;Deploying client to $(SERVER)...\a"
	scp ${WEBDIST}/* ${SERVER}
	@echo -en "\033]0;Terminal\a"

deploy-server: webserver
	@echo -en "\033]0;Deploying server to $(SERVER)...\a"
	scp ${SERVER_PCK} ${SERVER}
	@echo -en "\033]0;Terminal\a"

edit:
	@echo -en "\033]0;Godot editor\a"
	${GODOT} project.godot
	@echo -en "\033]0;Terminal\a"

deploy: deploy-client deploy-server

clean:
	rm -rf dist/*
