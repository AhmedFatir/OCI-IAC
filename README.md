# OCI Infrastructure as Code (OCI-IAC)

## Overview

- This project provides a comprehensive setup for deploying and managing infrastructure on [**Oracle Cloud Infrastructure (OCI)**](https://www.oracle.com/cloud/) using [**Terraform**](https://www.terraform.io/).
- It includes configurations for setting up an [**Oracle Kubernetes Engine (OKE)**](https://www.oracle.com/cloud/cloud-native/kubernetes-engine/) cluster and a [**Jenkins**](https://www.jenkins.io/) server for CI/CD pipelines.

## Architecture

```
                   ┌──────────────────┐
                   │                  │
                   │  OCI Dashboard   │
                   │                  │
                   └────────┬─────────┘
                            │
                            ▼
         ┌─────────────────────────────────────────────────┐
         │                 OCI Region                      │
         │                                                 │
         │   ┌─────────────┐        ┌────────────┐         │
         │   │             │◄───────┤            │         │
         │   │ OKE Cluster │        │  Jenkins   │◄────┐   │
         │   │             │        │            │     │   │
         │   └─────────────┘        └────────────┘     │   │
         │                                             │   │
         └─────────────────────────────────────────────┘   │
                                                           │
                                                           │
                      ┌─────────────────┐                  │
                      │                 │                  │
                      │  GitHub Repo    ├──────────────────┘
                      │                 │
                      └─────────────────┘
```

**CI/CD Flow:**
1. Jenkins pulls code from the GitHub repository
2. Jenkins builds, tests, and packages the application
3. Jenkins deploys the application to the OKE cluster

## Directory Structure

- `oci-dashboard/`
  - `resources/`
    - `terraform/`
      - `oke_cluster/`: Terraform configurations for OKE cluster.
      - `jenkins/`: Terraform configurations for Jenkins server.
    - `scripts/`: Shell scripts for various automation tasks.
  - `entrypoint.sh`: Entrypoint script for Docker container.
  - `Dockerfile`: Dockerfile to build the OCI dashboard image.

## Prerequisites

- Docker
- Docker Compose
- Git

## Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd OCI-IAC
   ```

2. **Copy the example environment file and set the required variables:**
   ```bash
   cp .env.example .env
   # Edit the .env file and set the values accordingly
   ```

3. **Build and start the Docker containers:**
   ```bash
   make
   ```

## Terraform Modules

### OKE Cluster

- **Variables:**
  - `tenancy_ocid`
  - `user_ocid`
  - `fingerprint`
  - `private_key_path`
  - `region`

- **Provider Configuration:**
  - `provider.tf`

- **Network Module:**
  - `modules/network/`

- **Cluster Module:**
  - `modules/cluster/`

### Jenkins

- **Variables:**
  - `tenancy_ocid`
  - `user_ocid`
  - `fingerprint`
  - `private_key_path`
  - `region`

- **Provider Configuration:**
  - `provider.tf`

- **Network Module:**
  - `modules/network/`

- **Compute Module:**
  - `modules/compute/`

## Scripts

- **SSH into Jenkins instance:**
  - `resources/scripts/ssh.sh`

- **Configure OCI CLI and kubectl:**
  - `resources/scripts/conf.sh`

- **Clean up resources:**
  - `resources/scripts/cleanup.sh`

## Docker

- **Build and run the Docker container:**
  - `Dockerfile`
  - `docker-compose.yml`

## Makefile Commands

- `make all`: Build and start the Docker containers.
- `make down`: Stop and remove the Docker containers.
- `make stop`: Stop the Docker containers.
- `make start`: Start the Docker containers.
- `make clean`: Clean up the resources.
- `make prune`: Prune Docker system.
- `make re`: Rebuild and start the Docker containers.
- `make oci`: Access the OCI dashboard container.

