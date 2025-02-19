ARG BASE_IMAGE

FROM $BASE_IMAGE

ARG HOST_UID
ARG HOST_GID



# Create specified user with home directory
RUN mkdir -p /home/ace-agent
RUN groupadd ace-agent --gid $HOST_GID \
    && useradd ace-agent --uid $HOST_UID --gid $HOST_GID -d /home/ace-agent \
    && chown -R $HOST_UID:$HOST_GID /home/ace-agent

##############################
# Install custom dependencies 
##############################

WORKDIR /home/ace-agent
USER $HOST_UID:$HOST_GID