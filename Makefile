DOCKER_IMAGE_NAME := dotfiles

#
# Docker
#

.PHONY: docker
docker:
	@if ! docker inspect $(DOCKER_IMAGE_NAME) &>/dev/null; then \
		docker build -t $(DOCKER_IMAGE_NAME) . \
			--build-arg USERNAME="$$(whoami)" \
			--build-arg USER_UID="$$(id -u)" \
			--build-arg USER_GID="$$(id -g)"; \
	fi
	docker run -it --rm \
		--hostname dotfiles-test \
		$(DOCKER_IMAGE_NAME) /bin/bash --login

.PHONY: docker-rebuild
docker-rebuild:
	docker build -t $(DOCKER_IMAGE_NAME) . \
		--no-cache \
		--build-arg USERNAME="$$(whoami)" \
		--build-arg USER_UID="$$(id -u)" \
		--build-arg USER_GID="$$(id -g)"

#
# Chezmoi
#

.PHONY: init
init:
	chezmoi init --apply --verbose

.PHONY: update
update:
	chezmoi apply --verbose

.PHONY: reset
reset:
	chezmoi state delete-bucket --bucket=scriptState

.PHONY: diff
diff:
	chezmoi diff

.PHONY: data
data:
	chezmoi data
