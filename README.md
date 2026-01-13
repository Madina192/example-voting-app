# Example Voting App

A simple distributed application running across multiple Docker containers.

## Getting started

Download [Docker Desktop](https://www.docker.com/products/docker-desktop) for Mac or Windows. [Docker Compose](https://docs.docker.com/compose) will be automatically installed. On Linux, make sure you have the latest version of [Compose](https://docs.docker.com/compose/install/).

This solution uses Python, Node.js, .NET, with Redis for messaging and Postgres for storage.

Run in this directory to build and run the app:

```shell
docker compose up
```

The `vote` app will be running at [http://localhost:8080](http://localhost:8080), and the `results` will be at [http://localhost:8081](http://localhost:8081).

Alternately, if you want to run it on a [Docker Swarm](https://docs.docker.com/engine/swarm/), first make sure you have a swarm. If you don't, run:

```shell
docker swarm init
```

Once you have your swarm, in this directory run:

```shell
docker stack deploy --compose-file docker-stack.yml vote
```

## Run the app in Kubernetes

The folder k8s-specifications contains the YAML specifications of the Voting App's services.

Run the following command to create the deployments and services. Note it will create these resources in your current namespace (`default` if you haven't changed it.)

```shell
kubectl create -f k8s-specifications/
```

The `vote` web app is then available on port 31000 on each host of the cluster, the `result` web app is available on port 31001.

To remove them, run:

```shell
kubectl delete -f k8s-specifications/
```

## Architecture

![Architecture diagram](architecture.excalidraw.png)

* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time

## Notes

The voting application only accepts one vote per client browser. It does not register additional votes if a vote has already been submitted from a client.

This isn't an example of a properly architected perfectly designed distributed app... it's just a simple
example of the various types of pieces and languages you might see (queues, persistent data, etc), and how to
deal with them in Docker at a basic level.


# Example Voting App – Deployment Guide

**Key Features:**
* **Cross-Cloud Deployment:** Deployed on AWS (Amazon Web Services) us-east-1
* **Server** t3.micro
* **Infrastructure as Code:** Automated provisioning using Terraform.
* **CI/CD Pipeline:** Automated deployment pipeline triggered by code changes.
* **Kubernetes**  K3s is a smaller and simpler Kubernetes
---

## 1. Cloud Infrastructure Architecture

### Components
* **Cloud Provider:** AWS (Region: `us-east-1`).
* **Compute:** Amazon EC2 (`t3.micro` instance).
* **Orchestration:** K3s (Lightweight Kubernetes).
* **Networking:** AWS Security Groups acting as a firewall.

### Infrastructure as Code (Terraform)
The infrastructure is defined in `main.tf`. It performs the following operations:
1.  **Security Group (`online_vote_sg`):** Configures strict ingress rules.
    * `Port 22`: SSH access for the CI/CD pipeline.
    * `Port 80`: HTTP access for the Voting App frontend.
    * `Port 30000-32767`: NodePort range for Kubernetes services.
2.  **Key Pair (`project-key`):** Injects a secure SSH key for passwordless authentication.
3.  **EC2 Instance:** Provisions a `t3.micro` Ubuntu server.
4.  **User Data Script:** A bash script runs on startup to:
    * Install Docker.
    * Install K3s (Single-node Kubernetes cluster).

## 2. CI/CD Pipeline

### Overview
The Continuous Deployment pipeline is built using **GitHub Actions**. It ensures that any change made to the code is automatically reflected in the production environment without manual server intervention.

### Workflow Steps (`.github/workflows/deploy.yml`)
1.  **Trigger:** The pipeline listens for `push` events to the `main` branch.
2.  **Remote Access:** Uses `appleboy/ssh-action` to SSH into the AWS EC2 instance using secrets stored in the GitHub repository.
3.  **Code Update:** Navigates to the project directory and executes `git pull`.
4.  **Kubernetes Update:**
    * Applies any changes to manifests (`kubectl apply -f .`).
    * Forces a zero-downtime update using `kubectl rollout restart`.


## 3. Deployment Instructions

### Prerequisites
* Terraform installed.
* AWS Credentials configured.
* GitHub Repository Secrets set: `SERVER_IP`, `SSH_PRIVATE_KEY`.

### Steps
1.  **Provision Infrastructure:**
    ```bash
    cd terraform
    terraform init
    terraform apply --auto-approve
    ```
2.  **Initial Setup (One-time):**
    SSH into the new server IP and clone the repository:
    ```bash
    ssh -i project-key.pem ubuntu@<SERVER_IP>
    git clone [https://github.com/YOUR_USERNAME/example-voting-app.git](https://github.com/YOUR_USERNAME/example-voting-app.git)
    ```
3.  **Access Application:**
    Open `http://<SERVER_IP>` in your browser.
