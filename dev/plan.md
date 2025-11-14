# Development Environment Setup Plan

## Overview

This plan outlines the steps to configure a development environment on top of the base Omarchy setup. The `dev.sh` script will handle the installation of development-specific tools, applications, and configurations & always be run after the `setup.sh` script on the machine.

## 1. Package Installation

- Install development-related packages from `dev/pkglist.txt`. This will include tools like:
  - IDEs and code editors (if not in base install)
  - Docker and containerization tools
  - Language runtimes (Node.js, Go, Python, etc.)
  - Database clients (e.g., Beekeeper Studio)
  - API testing tools (e.g., Postman)

## 2. Web Applications

- Deploy development-focused web applications from the `webapps/` directory that are relevant for development work (e.g., GitHub, project management tools).

## 3. Configuration

- Apply any development-specific configurations. This might include:
  - Git configurations (`.gitconfig`)
  - Shell customizations for development (`.bashrc`, `.zshrc`)
  - VS Code settings and extensions

## 4. Script Logic (`dev.sh`)

- The `dev.sh` script will be idempotent.
- It will read package lists from the `dev/` directory.
- It will handle copying or symlinking configuration files as needed.
