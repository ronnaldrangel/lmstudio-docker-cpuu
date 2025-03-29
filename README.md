# LMStudio Docker Deployment

This repository contains the necessary files to run [LMStudio](https://lmstudio.ai), an application for language model interaction, within a Docker container. The setup includes configuration files for both the entry point script, health check, Docker Compose file, Dockerfile, and HTTP server configuration.


## Introduction
LMStudio is a tool designed for interacting with language models, providing a seamless experience through a web interface. This setup uses Docker to containerize the application and deployment tools like Docker Compose for easy management of multiple containers.

## Prerequisites
Before you begin, ensure that your system meets the following requirements:
- [Docker](https://docs.docker.com/get-docker/) installed on your machine.
- Docker Compose (usually included with Docker Engine).
- A suitable environment to run the LMStudio container (e.g., a Linux server or local machine capable of running Docker containers).

## Getting Started
1. Clone this repository to your local machine:
    ```bash
    git clone https://github.com/n0mer1/lmstudio-docker.git LMStudio
    cd LMStudio
    ```
2. Review the `docker-compose.yml` file to ensure it meets your requirements. Adjust any environment variables or paths as necessary.
3. Download the LMStudio installer:
    ```bash
    wget https://installers.lmstudio.ai/linux/x64/0.3.14-5/LM-Studio-0.3.14-5-x64.AppImage
    ```
4. Build and run the Docker containers using:
    ```bash
    docker-compose up -d --build
    ```

## Configuration

Configuration settings are managed via environment variables and configuration files as follows:
- **Environment Variables**: Set these in the Docker Compose file or directly in the `.env` file if used.
  - `CONTEXT_LENGTH`: Defines the context length for model interactions.
  - `MODEL_PATH`: Path to the specific language model to be loaded.
  - `MODEL_IDENTIFIER`: Identifier for the loaded model.


## Running the Services
To start the services defined in `docker-compose.yml`, use the following command from the project directory:
```bash
docker-compose up -d
```
This command will run the containers in detached mode, allowing you to continue using your terminal without interruption.

To stop the services, use:
```bash
docker-compose down
```

## Troubleshooting
If you encounter issues during setup or usage:
1. Check the logs for errors:
   ```bash
   docker-compose logs -f lmstudio
   ```
2. Ensure all required environment variables are set correctly in the Docker Compose file or `.env` file.
3. Verify that the container is running:
   ```bash
   docker ps
   ```

## Contributing
Contributions to this project are welcome. Please open an issue for bugs or feature requests and submit a pull request with proposed changes. For major changes, please discuss them in advance.
