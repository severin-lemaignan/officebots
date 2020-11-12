
PROJECT_NAME="bots-at-work"

HTML5_CLIENT=html5/index.pck
SERVER_PCK=${PROJECT_NAME}-server.zip

DIST=dist
GODOT=${HOME}/applis/godot/Godot_v3.2.1-stable_x11.64


${DIST}/${HTML5_CLIENT}:
	mkdir -p ${DIST}/html5
	${GODOT} --export HTML5 ${DIST}/html5/index.html

html: ${DIST}/${HTML5_CLIENT}

${DIST}/${SERVER_PCK}:
	${GODOT} --export-pack linux ${DIST}/${SERVER_PCK}

server: ${DIST}/${SERVER_PCK}

deploy-client: html
	scp ${DIST}/html5/* kimsufi:research-severin/bots-at-work

deploy-server: server
	scp ${DIST}/${SERVER_PCK} kimsufi:research-severin/bots-at-work

clean:
	rm -rf dist/*
