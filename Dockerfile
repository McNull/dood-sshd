FROM ubuntu:24.04 AS base

ARG DEV_USER=null
ARG DEV_USER_ID=1000
ARG DEV_DOCKER_GROUP=docker
ARG DEV_DOCKER_GROUP_ID=999
ARG DEV_GROUP_ID=1000
ARG DEV_HOSTNAME=dood-sshd

ENV DEV_USER=${DEV_USER}
ENV DEV_USER_ID=${DEV_USER_ID}
ENV DEV_DOCKER_GROUP=${DEV_DOCKER_GROUP}
ENV DEV_DOCKER_GROUP_ID=${DEV_DOCKER_GROUP_ID}
ENV DEV_GROUP_ID=${DEV_GROUP_ID}
ENV DEV_HOSTNAME=${DEV_HOSTNAME}

ENV TERM=xterm-256color

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


RUN groupadd -g ${DEV_GROUP_ID} ${DEV_USER} \
    && useradd --uid ${DEV_USER_ID} --gid ${DEV_GROUP_ID} --groups sudo --create-home --shell /bin/bash ${DEV_USER} \
    && mkdir -p /home/${DEV_USER}/data \
    && chown ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/data \
    && echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${DEV_USER} \
    && chmod 0440 /etc/sudoers.d/${DEV_USER}

# ----------------------------------
# docker setup
FROM base AS docker_setup

# Create docker group 
# ARG DEV_DOCKER_GROUP_ID=999
# ENV DEV_DOCKER_GROUP_ID=${DEV_DOCKER_GROUP_ID}
RUN groupadd -g ${DEV_DOCKER_GROUP_ID} ${DEV_DOCKER_GROUP}

# Add user to docker group
RUN usermod -aG ${DEV_DOCKER_GROUP} ${DEV_USER}

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

COPY ./authorized_keys /home/${DEV_USER}/.ssh/authorized_keys
RUN touch /home/${DEV_USER}/.ssh/config

RUN chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.ssh \
    && chmod 700 /home/${DEV_USER}/.ssh \
    && chmod 600 /home/${DEV_USER}/.ssh/authorized_keys \
    && chmod 644 /home/${DEV_USER}/.ssh/config

RUN mkdir -p /var/run/sshd
# Generate SSH host keys
# RUN ssh-keygen -A
EXPOSE 22

USER ${DEV_USER}

# # Set Git global configuration for user identity
RUN git config --global user.email "${DEV_USER}@${DEV_HOSTNAME}" && \
    git config --global user.name "${DEV_USER}"

CMD ["sudo", "/bin/sh", "-c", "trap 'kill -TERM $PID' TERM INT; /usr/sbin/sshd -D & PID=$!; wait $PID; trap - TERM INT; wait $PID"]