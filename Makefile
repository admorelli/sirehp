# This Makefile contains targets for building and running the KerkoApp Docker image.
# Change NAME if you wish to build your own image.
IMAGE_NAME := allfa/sirehp

CONTAINER_NAME := sirehp
MAKEFILE_DIR := $(dir $(CURDIR)/$(lastword $(MAKEFILE_LIST)))
HOST_PORT := 8080
HOST_INSTANCE_PATH := $(MAKEFILE_DIR)/instance
HOST_DEV_LOG := /tmp/kerkoapp-dev-log

SECRETS := $(HOST_INSTANCE_PATH)/.secrets.toml
CONFIG := $(HOST_INSTANCE_PATH)/config.toml
DATA := $(HOST_INSTANCE_PATH)/kerko/index

VENV = venv
VENV_BIN = $(VENV)/bin
REQUIREMENTS_TXT = requirements/run.txt
PYTHON = $(VENV_BIN)/python3
PIP = $(VENV_BIN)/pip
FLASK = $(VENV_BIN)/flask

#
# Running targets.
#
# These work if the image exists, either pulled or built locally.
#

.PHONY: help
help:
	@echo "Commands for using SireHP with Docker:"
	@echo "    make build_image"
	@echo "        Build a SireHP Docker image locally."
	@echo "    make clean_image"
	@echo "        Remove the SireHP Docker image."
	@echo "    make shell"
	@echo "        Start an interactive shell within the KerkoApp Docker container."
	@echo "    make show_version"
	@echo "        Print the version that would be used if the KerkoApp Docker image was to be built."
	@echo "\nCommands related to KerkoApp development:"
	@echo "    make publish"
	@echo "        Publish the SireHP Docker image on DockerHub."
	@echo "    make build_container"
	@echo "        Build a SireHP Docker container."
	@echo "    make build_image"
	@echo "        Build Docker Image"
	@echo "    make run"
	@echo "        Run SireHP on the web with Docker Compose."
	@echo "    make daemon"
	@echo "        Run SireHP on the web with Docker Compose as a daemon."
	@echo "    make clean_kerko"
	@echo "        Run the 'kerko clean' command from within the KerkoApp Docker container."
	@echo "    make run-dev"
	@echo "        Run SireHP from venv."
	@echo "    make requirements"
	@echo "        Pin the versions of Python dependencies in requirements files."
	@echo "    make requirements-upgrade"
	@echo "        Pin the latest versions of Python dependencies in requirements files."
	@echo "    make upgrade"
	@echo "        Update Python dependencies and install the upgraded versions."


# On some systems, extended privileges are required for Gunicorn to launch within the container,
# hence the use of the --privileged option below. For production use, you may want to verify whether
# this option is really required for your system, or grant finer grained privileges. See
# https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
.PHONY: run
run: | $(DATA) $(SECRETS) $(CONFIG) stop
	docker compose up

.PHONI: run-dev
run-dev: | $(VENV)/bin/activate $(DATA) $(SECRETS) $(CONFIG)
	$(FLASK) run

.PHONY: daemon
daemon: | $(DATA) $(SECRETS) $(CONFIG) stop
	docker compose up -d

.PHONY: stop
stop:
	docker compose down

.PHONY: shell_kerko
shell_kerko:
	docker compose exec -ti $(CONTAINER_NAME) /bin/ash

.PHONY: clean_kerko
clean_kerko: | $(SECRETS) $(CONFIG)
	docker compose exec -t $(CONTAINER_NAME) flask kerko clean everything

$(DATA): | $(SECRETS) $(CONFIG)
	@echo "[INFO] It looks like you have not run the 'flask kerko sync' command. Running it for you now!"
	$(MAKE) sync

$(SECRETS):
	@echo "[ERROR] You must create '$(SECRETS)'."
	@exit 1

$(CONFIG):
	@echo "[ERROR] You must create '$(CONFIG)'."
	@exit 1

#
# Building and publishing targets.
#
# These work from a clone of the KerkoApp Git repository.
#

HASH = $(shell git rev-parse HEAD 2>/dev/null)
VERSION = $(shell git describe --exact-match --tags HEAD 2>/dev/null)

.PHONY: publish build_image
publish: | build_image .git
ifneq ($(shell git status --porcelain 2> /dev/null),)
	@echo "[ERROR] The Git working directory has uncommitted changes."
	@exit 1
endif
ifeq ($(findstring .,$(VERSION)),.)
	docker tag $(IMAGE_NAME) $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):$(VERSION)
	docker tag $(IMAGE_NAME) $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):latest
else
	@echo "[ERROR] A proper version tag on the Git HEAD is required to publish."
	@exit 1
endif

.PHONY: build_image
build_image: | .git
ifeq ($(findstring .,$(VERSION)),.)
	docker build -t $(IMAGE_NAME) --no-cache --label "org.opencontainers.image.version=$(VERSION)" --label "org.opencontainers.image.created=$(shell date --rfc-3339=seconds)" $(MAKEFILE_DIR)
else
	docker build -t $(IMAGE_NAME) --no-cache --label "org.opencontainers.image.revision=$(HASH)" --label "org.opencontainers.image.created=$(shell date --rfc-3339=seconds)" $(MAKEFILE_DIR)
endif

.PHONY: build_container
build_container: | .git
	docker compose build --no-cache --pull

.PHONY: show_version clean_image requirements requirements-upgrade upgrade update sync
show_version: | .git
ifeq ($(findstring .,$(VERSION)),.)
	@echo "$(VERSION)"
else
	@echo "$(HASH)"
endif

.PHONY: clean_image requirements requirements-upgrade upgrade update sync
clean_image: | .git
ifeq ($(findstring .,$(VERSION)),.)
	docker rmi $(IMAGE_NAME):$(VERSION)
else
	docker rmi $(IMAGE_NAME)
endif

.git:
	@echo "[ERROR] This target must run from a clone of the KerkoApp Git repository."
	@exit 1

requirements/run.txt: requirements/run.in
	$(PIP)-compile --resolver=backtracking requirements/run.in -o requirements/run.txt

requirements/docker.txt: requirements/run.txt requirements/docker.in
	$(PIP)-compile --resolver=backtracking requirements/docker.in -o requirements/docker.txt

requirements/dev.txt: requirements/run.txt requirements/dev.in
	$(PIP)-compile --allow-unsafe --resolver=backtracking requirements/dev.in -o requirements/dev.txt

.PHONY: requirements
requirements: requirements/run.txt requirements/docker.txt requirements/dev.txt

.PHONY: requirements-upgrade upgrade
requirements-upgrade: | $(VENV)/bin/activate upgrade
	$(VENV_BIN)/pre-commit autoupdate
	$(PIP) install --upgrade pip pip-tools
	$(PIP)-compile --upgrade --resolver=backtracking --rebuild requirements/run.in -o requirements/run.txt
	$(PIP)-compile --upgrade --resolver=backtracking --rebuild requirements/docker.in -o requirements/docker.txt
	$(PIP)-compile --upgrade --allow-unsafe --resolver=backtracking --rebuild requirements/dev.in -o requirements/dev.txt

.PHONY: upgrade
upgrade:
	$(PIP)-sync requirements/dev.txt

.PHONY: update sync daemon
update:
	$(PIP) install -r requirements/dev.txt

.PHONY: sync daemon
sync: | daemon
	docker compose exec $(CONTAINER_NAME) flask --debug kerko sync

$(VENV)/bin/activate: $(REQUIREMENTS_TXT)
	python3 -m venv ./venv
	$(PIP) install -r $(REQUIREMENTS_TXT)


