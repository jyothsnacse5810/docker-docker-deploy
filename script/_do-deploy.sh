#!/bin/sh

echo -e "\n${INFO_COLOR}Deploying at remote target ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}\n"

deployCmd="\
	cd ${DEPLOY_HOME} && \
	if [ ! -z \"${REGISTRY_USER}\" ] ; \
	then \
		docker login -u \"${REGISTRY_USER}\" -p \"${REGISTRY_PASS}\" ${REGISTRY_URL} ; \
		deployAuthParam=\"--with-registry-auth\" ; \
	else \
		deployAuthParam=\"\" ; \
	fi ; \
	if [ ${FORCE_DOCKER_COMPOSE} -eq 0 ] && docker stack ls > /dev/null 2> /dev/null ; \
	then \
		composeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g') && \
		${GREP_BIN} -v '^[#| ]' .env | sed -r \"s/(\w+)=(.*)/export \1='\2'/g\" > .env-deploy && \
		env -i /bin/sh -c \". \$(pwd)/.env-deploy && \
			docker stack deploy -c \${composeFileSplitted} \${deployAuthParam} ${STACK}\" ; \
	else \
		composeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -f /g') && \
		composeCmd=\"docker-compose -f \${composeFileSplitted} -p ${STACK}\" && \
		\${composeCmd} stop ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} rm -f ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} pull ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} up -d ${SERVICES_TO_DEPLOY} ; \
	fi"

cleanDeployCmd="ssh ${SSH_PARAMS} \"${SSH_REMOTE}\" \"rm -rf ${DEPLOY_HOME}\""

if ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${deployCmd}"
then
	echo -e "${PASS_COLOR}Services successfully deployed!${NULL_COLOR}"
	if [ ${OMIT_CLEAN_DEPLOY} -eq 0 ]
	then
		eval "${cleanDeployCmd}"
	else
		echo -e "${INFO_COLOR}Deployment resources cleaning omitted${NULL_COLOR}"
	fi
else
	echo -e "${FAIL_COLOR}Services deployment failed!${NULL_COLOR}"
	eval "${cleanDeployCmd}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi
