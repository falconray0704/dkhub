FROM rayruan/amd64_ubuntu:base_bionic

ARG VSCODE_REL_VERSION
ARG OSENV_DOCKER_CPU_ARCH

RUN apt-get update \
 && apt-get install -y \
    curl \
    dumb-init \
    zsh \
    htop \
    locales \
    man \
    nano \
    git \
    procps \
    openssh-client \
    sudo \
    vim \
    lsb-release \
  && rm -rf /var/lib/apt/lists/*

# https://wiki.debian.org/Locale#Manually
RUN sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen \
  && locale-gen
ENV LANG=en_US.UTF-8

RUN adduser --gecos '' --disabled-password coder && \
  echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

COPY code-server_${VSCODE_REL_VERSION}_${OSENV_DOCKER_CPU_ARCH}.deb /tmp/
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN dpkg -i /tmp/code-server*$(dpkg --print-architecture).deb && rm /tmp/code-server*.deb

COPY sysCfg /home/coder/sysCfg
RUN echo "*** Installing code-server extensions ***" \
    && ls -al /home/coder/sysCfg \
    && cd /home/coder/sysCfg/vscode \
    && ln -s ../libShell/.env_setup_amd64_ubt_1804 .env_setup \
    && cd - \
    && chown -hR coder:coder /home/coder/sysCfg
 
EXPOSE 8080
# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER 1000
ENV USER=coder
WORKDIR /home/coder

#RUN cd /home/coder/sysCfg/vscode \
#    && ./run.sh -c install -l "server_extensions" \
#    && cd -
    
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]


