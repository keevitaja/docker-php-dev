FROM bitnami/mariadb:10.4

ARG DOCKER_APP_UID

USER ${DOCKER_APP_UID}
