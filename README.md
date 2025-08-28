# dood-sshd

This repository builds a Docker image for "Docker-out-of-Docker" (dood) with SSH access.

## What is dood?

**dood** stands for "Docker-out-of-Docker." Instead of running Docker inside a container (DinD), dood shares the host’s Docker socket (`/var/run/docker.sock`) with the container. This allows you to run Docker commands inside the container, controlling the host’s Docker daemon, without the overhead and security risks of running Docker-in-Docker.

## What does this image do?

- Provides a development environment with many useful tools (git, vim, Python, databases, etc.).
- Installs Docker CLI and configures the user to access the host’s Docker daemon.
- Sets up an SSH server so you can connect to the container remotely.
- Mounts a persistent `./data` directory for your files.

## Usage

1.  **Copy and edit environment file:**

    ```sh
    cp example.env .env
    ```

    Edit `.env` to set your desired username, user/group IDs, hostname, and SSH port.

2.  **Create the data directory:**

    ```sh
    mkdir ./data
    ```

    This directory will be mounted into the container at `/home/<DEV_USER>/data`.

3.  **Start the container:**

    ```sh
    docker compose up
    ```

    The container will be accessible via SSH on the port specified in `.env`.

## Notes

- The container shares the host’s Docker socket, so any Docker commands run inside the container will affect the host.
- Make sure to create the `./data` directory before running `docker compose up` to avoid mount errors.
