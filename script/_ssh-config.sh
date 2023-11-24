#!/bin/sh

if [ -z "${SSH_REMOTE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SSH_REMOTE' in environment${NULL_COLOR}"
	exit 1
fi

remoteHost=$(echo "${SSH_REMOTE}" | cut -f 2 -d '@')

if [ -z "${remoteHost}" ]
then
	echo -e "${FAIL_COLOR}Remote host not found, define 'SSH_REMOTE' with remote user and hostname (like 'ssh-user@ssh-remote')${NULL_COLOR}"
	exit 1
fi

if [ -z "${DEPLOY_KEY}" ]
then
	echo -e "${FAIL_COLOR}You must define 'DEPLOY_KEY' in environment, with a SSH private key accepted by remote host${NULL_COLOR}"
	exit 1
fi

# Se prepara la identidad para conectar al servidor de despliegue.
eval "$(ssh-agent)" > /dev/null
echo "${DEPLOY_KEY}" | tr -d '\r' | ssh-add - > /dev/null 2>&1

closeSshCmd="ssh ${SSH_PARAMS} -q -O exit \"${SSH_REMOTE}\""
