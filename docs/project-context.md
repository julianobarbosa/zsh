# Project Context: ZSH Configuration Management

## Summary

The `zsh-tool` project is a sophisticated Zsh configuration management framework designed to standardize and streamline shell environments for teams. It employs a "Configuration as Code" paradigm, where a central `config.yaml` file defines a team's standard shell environment, including plugins, themes, aliases, exports, and PATH modifications. The system is modular, with core logic organized in the `lib` directory, and a robust installation process that ensures idempotency and user-specific overrides.

## Core Architecture and Components

The project's architecture is centered around a few key components:

### `install.sh`

*   **Role**: Main entry point for installing and managing the `zsh-tool`. It orchestrates the setup process, manages the installation directory, and provides high-level commands.
*   **Key Features**: Idempotent installation, setup of Oh My Zsh, generation of `.zshrc` from a template, and handling of user-specific configurations.

### `lib/core/utils.zsh`

*   **Role**: Provides foundational helper functions used across the entire tool.
*   **Key Features**: Logging, state management (using a `state.json` file), and dependency checks, ensuring consistent operation and error handling.

### `lib/install/config.zsh`

*   **Role**: Contains the core business logic for the "Configuration as Code" paradigm.
*   **Key Features**: Responsible for parsing the `config.yaml` file, validating its structure, and dynamically generating the user's `.zshrc` file based on the parsed configuration and the `zshrc.template`.

### `templates/config.yaml`

*   **Role**: Defines the data model and the desired state for the Zsh environment. This is the central configuration file where teams specify their standard shell settings.
*   **Key Features**:
    *   **Plugins**: Lists Oh My Zsh plugins (e.g., `git`, `docker`, `kubectl`).
    *   **Themes**: Specifies the default Oh My Zsh theme and lists available options.
    *   **Aliases**: Defines common command aliases (e.g., `gs` for `git status`).
    *   **Exports**: Sets environment variables (e.g., `EDITOR`, `VISUAL`).
    *   **Paths**: Manages `PATH` modifications (prepends or appends directories).
    *   **Atuin Integration**: Configuration for Atuin shell history (enabled, import, sync, search modes).
    *   **Amazon Q Developer CLI Integration**: Configuration for Amazon Q CLI (enabled, lazy loading, compatibility, disabled CLIs).

### `templates/zshrc.template`

*   **Role**: The template that transforms the structured data from `config.yaml` into a functional `.zshrc` file.
*   **Key Features**:
    *   Includes placeholders (`{{theme}}`, `{{plugins}}`, `{{aliases}}`, `{{exports}}`, `{{paths}}`) that are populated by `lib/install/config.zsh`.
    *   Loads Oh My Zsh.
    *   Integrates user customizations from `~/.zshrc.local` if it exists.
    *   Loads `zsh-tool`'s own functions.

## Key Concepts and Business Logic

### Configuration as Code

The project's core philosophy is to manage Zsh configurations declaratively through `config.yaml`. This allows teams to:
*   **Standardize environments**: Ensure all team members have a consistent shell setup.
*   **Version control configurations**: Track changes to the shell environment in a Git repository.
*   **Automate deployments**: Easily roll out consistent configurations to new machines or users.

### Idempotent Installation

The `install.sh` script is designed to be idempotent, meaning it can be run multiple times without causing unintended side effects. It handles:
*   **Backup**: Existing user configurations are backed up.
*   **Dependency Management**: Ensures Oh My Zsh and other prerequisites are correctly installed.
*   **Safe Updates**: Allows for seamless updates to the Zsh environment based on changes in `config.yaml`.

### User Customizations

Users can maintain their personal Zsh configurations without interfering with the team's standardized settings by using a `~/.zshrc.local` file. This file is sourced after the `zsh-tool`-managed section, allowing users to override or extend defaults.
