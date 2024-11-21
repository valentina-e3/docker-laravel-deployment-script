# **Automated Laravel Deployment with Docker Compose**

This repository contains a Bash script that automates the setup and deployment of a Dockerized Laravel application using Docker Compose. The script handles tasks such as cloning a GitHub repository, checking out the specified branch, running Docker Compose in detached mode, applying Laravel migrations, and cleaning up containers.

## **Requirements**

- **Git**: To clone the repository.
- **Docker**: To run Docker Compose and manage containers.
- **Docker Compose**: To define and run multi-container Docker applications.
- **YAML Parsing Tool (yq)**: For reading and extracting environment variables from the 
`deploy_config.yaml` configuration file.
- have a `deploy` folder inside the root folder of your laravel project, which you want to deploy, with a `docker-compose.yml` file inside it. You should set the `container_name` for your Laravel container to `laravelapp`, otherwise you would get an error when applying Laravel migrations.

## **What the script does**
- **Clones the Repository**: If the repository is not already cloned locally, it will be cloned from GitHub.
- **Checks Out the Branch**: The script will check out the specified branch, or create it if it doesn't exist.
- **Docker Compose Setup**: Runs Docker Compose to build and start the containers for the Laravel application in detached mode.
- **Runs Laravel Migrations**: Executes Laravel database migrations inside the `laravelapp` container.

## **Setup and Usage**

### **1. Configure the YAML File**
Create a `deploy_config.yaml` file in the directory where `deploy_laravel.sh` is located. This file contains all the necessary configuration for the script, including the GitHub repository URL, branch name which you want to deploy, and environment variables for Docker Compose.

#### Example of `deploy_config.yaml` configuration file

```bash
repository:
  url: "git@github.com:yourusername/your-laravel-project.git"
  branch: "main"

environment:
  APP_ENV: "production"
  APP_KEY: "base64:your-app-key-here"

  ...
```

### **2. Make the Script Executable**
Make the script executable by running:

```bash
chmod +x deploy_laravel.sh
```

### **3. Run the Script**

**Before running the script make sure you have a `deploy` folder inside your Laravel project in your remote repository with a working `docker-compose.yml` file and a container named `laravelapp` inside it!**

```bash
./deploy_laravel.sh
```

## **Stopping and Cleaning Up Containers**

If you want to stop and remove the containers after the deployment process, you should position yourself inside the `deploy` folder of your laravel project and run:

```bash
docker compose down
```
