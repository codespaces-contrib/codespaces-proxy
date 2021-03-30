#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

COPY library-scripts/sshd-debian.sh /tmp/library-scripts/
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && bash /tmp/library-scripts/sshd-debian.sh \
    && apt-get install -y redsocks iptables \
    && rm -rf /tmp/library-scripts

ENTRYPOINT ["/usr/local/share/ssh-init.sh"]
CMD ["sleep", "infinity"]
