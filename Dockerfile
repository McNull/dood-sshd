FROM ubuntu:24.04 AS base

RUN apt-get update \
	&& apt-get install -y \
	curl \
	git \
	build-essential \
	sudo \
	vim \
	wget \
  sqlite3 \ 
  iproute2 \ 
  netcat-traditional \
  iputils-ping \
  dnsutils \
  openssh-server \
  htop \
  unzip \
  zip \
  jq \
  # Shell enhancements
  bash-completion \
  tmux \
  tree \
  # Text processing
  ripgrep \
  # Debugging tools
  gdb \
  valgrind \
  strace \
  # Network tools
  net-tools \
  tcpdump \
  nmap \
  # Database clients
  postgresql-client \
  mysql-client \
  redis-tools \
  # Programming languages
  python3 \
  python3-pip \
  python3-venv \
  python-is-python3 \
  # System utilities
  rsync \
  sysstat \
  ncdu \
  # Security
  gnupg \
  openssl \
  ca-certificates \
  # Locale support
  locales \
  && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

ARG USER=null
ENV USER=${USER}
ARG USER_ID=1000
ENV USER_ID=${USER_ID}
ARG GROUP_ID=1000
ENV GROUP_ID=${GROUP_ID}
ARG HOSTNAME=dood-sshd
ENV HOSTNAME=${HOSTNAME}

ENV TERM=xterm-256color

RUN groupadd -g ${GROUP_ID} ${USER} \
    && useradd --uid ${USER_ID} --gid ${GROUP_ID} --groups sudo --create-home --shell /bin/bash ${USER} \
    && mkdir -p /home/${USER}/data \
    && chown ${USER}:${USER} /home/${USER}/data \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

# ----------------------------------
# docker setup
FROM base AS docker_setup

# Create docker group 
ARG DOCKER_GROUP_ID=999
ENV DOCKER_GROUP_ID=${DOCKER_GROUP_ID} 
RUN groupadd -g ${DOCKER_GROUP_ID} docker

# Add user to docker group
RUN usermod -aG docker ${USER}

# Add Docker's official GPG key:
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install the Docker packages.
RUN apt-get update && apt-get install -y docker-ce-cli

# -----------------------------------
# setup ssh server
FROM docker_setup AS ssh_setup
USER root

COPY ./authorized_keys /home/${USER}/.ssh/authorized_keys
RUN touch /home/${USER}/.ssh/config

RUN chown -R ${USER}:${USER} /home/${USER}/.ssh \
    && chmod 700 /home/${USER}/.ssh \
    && chmod 600 /home/${USER}/.ssh/authorized_keys \
    && chmod 644 /home/${USER}/.ssh/config

RUN mkdir -p /var/run/sshd
# Generate SSH host keys
# RUN ssh-keygen -A
EXPOSE 22

USER ${USER}

# # Set Git global configuration for user identity
RUN git config --global user.email "${USER}@${HOSTNAME}" && \
    git config --global user.name "${USER}"

CMD ["sudo", "/bin/sh", "-c", "trap 'kill -TERM $PID' TERM INT; /usr/sbin/sshd -D & PID=$!; wait $PID; trap - TERM INT; wait $PID"]