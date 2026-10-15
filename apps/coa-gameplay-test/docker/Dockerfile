ARG BASE_IMAGE=acore/ac-wotlk-worldserver:master
FROM ${BASE_IMAGE}
ARG DOCKER_USER=acore

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*

USER ${DOCKER_USER}
