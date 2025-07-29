#**********************************************************************
# Copyright 2018 Crown Copyright
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#**********************************************************************

FROM alpine:3.22.1

# Work from the shared git repo dir
WORKDIR /builder/shared

ARG ARGBASH_VERSION=2.11.0

ARG SEND_TO_STROOM_VERSION

# Pass in the uid/gid of the running user so we can use the same user id
# in the container so that any files created can be read outside the 
# container.
ARG USER_ID
ARG GROUP_ID    
# The gid of the docker group on the host, needed so we can add our
# non-root user to it to get access to the docker.sock
ARG DOCKER_GROUP_ID    

# Pass in the abs path to the repo root on the docker host
# Needed to allow us to mount it in containers we spawn from here.
ARG HOST_REPO_DIR    

# Set the user ID into an env var so the entrypoint can see it
ENV CONTAINER_USER_ID=$USER_ID
ENV HOST_REPO_DIR=$HOST_REPO_DIR
ENV SEND_TO_STROOM_VERSION=$SEND_TO_STROOM_VERSION

# Set tini as entrypoint
ENTRYPOINT ["/sbin/tini", "--", "/builder/docker-entrypoint.sh"]

CMD bash

RUN apk add --no-cache \
      shellcheck \
      autoconf \
      bash \
      curl \
      su-exec \
      tini \
    && curl -Ls https://github.com/matejak/argbash/archive/refs/tags/$ARGBASH_VERSION.tar.gz -o /tmp/$ARGBASH_VERSION.tar.gz \
    && apk del curl \
    && tar -xf /tmp/$ARGBASH_VERSION.tar.gz -C /builder/ \
    && rm /tmp/$ARGBASH_VERSION.tar.gz \
    && mv /builder/argbash-$ARGBASH_VERSION /builder/argbash \
    && echo "USER_ID: [$USER_ID]" \
    && echo "GROUP_ID: [$GROUP_ID]" \
    && echo \
    && echo "Ensuring group exists for group id [${GROUP_ID}]" \
    && group_name="$(cat /etc/group | grep ":${GROUP_ID}:" | awk -F ":" '{ print $1 }')" \
    && echo "group_name from /etc/group: [$group_name"] \
    && if [ -n "${group_name}" ]; then echo "Found group [${group_name}] with id ${GROUP_ID}"; fi \
    && if [ ! -n "${group_name}" ]; then echo "Creating group [builder] with id ${GROUP_ID}"; fi \
    && if [ ! -n "${group_name}" ]; then addgroup -g "$GROUP_ID" -S builder; fi \
    && if [ ! -n "${group_name}" ]; then group_name="builder"; fi \
    && echo "group_name: [$group_name"] \
    && echo \
    && echo "Ensuring user exists for user id [${USER_ID}]" \
    && user_name="$(getent passwd "$USER_ID" | cut -d: -f1)" \
    && echo "user_name from passwd with id ${USER_ID}: [$user_name]" \
    && if [ -n "${user_name}" ]; then echo "Found user [${user_name}] with id ${USER_ID}"; fi \
    && if [ ! -n "${user_name}" ]; then echo "Creating user [builder] with id ${USER_ID}"; fi \
    && if [ ! -n "${user_name}" ]; then adduser -u "$USER_ID" -S -s /bin/false -D -G "${group_name}" builder; fi \
    && if [ ! -n "${user_name}" ]; then user_name="builder"; fi \
    && echo "user_name: [$user_name]" \
    && echo \
    && mkdir -p /builder/shared \
    && chown -R $USER_ID:$GROUP_ID /builder

    #&& addgroup -g $GROUP_ID -S builder \
    #&& adduser -u $USER_ID -S -s /bin/false -D -G builder builder \

COPY --chown=$USER_ID:$GROUP_ID docker-entrypoint.sh /builder/

USER $USER_ID
