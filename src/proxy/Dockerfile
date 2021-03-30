#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

FROM debian:stable-slim

ARG DANTED_PORT=1080
COPY ./danted.conf /tmp/danted.conf
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install -y dante-server \
    && sed -i "s/1080/${DANTED_PORT}/g" /tmp/danted.conf \
    && cp -f /tmp/danted.conf /etc/danted.conf \
    && echo '#!/bin/sh\n/etc/init.d/danted start\nexec "$@"' > /usr/local/bin/danted-init \
    && chmod +x /usr/local/bin/danted-init

ENTRYPOINT [ "/usr/local/bin/danted-init" ]
CMD [ "/bin/sh", "-c", "while sleep 1000; do :; done" ]