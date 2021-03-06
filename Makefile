BUILD_DIR	:= build
VPATH			:= $(BUILD_DIR)

CC				:= go build
GITHASH 	:= $(shell git rev-parse HEAD)
GITBRANCH	:= $(shell git rev-parse --abbrev-ref HEAD)
DATE			:= $(shell TZ=UTC date -u '+%Y-%m-%dT%H:%M:%SZ UTC')
DFLAGS		:= -race
CFLAGS		:= -X 'github.com/ovh/tsl/cmd.githash=$(GITHASH)' -X 'github.com/ovh/tsl/cmd.date=$(DATE)' -X 'github.com/ovh/tsl/cmd.gitbranch=$(GITBRANCH)'
CROSS			:= GOOS=linux GOARCH=amd64

FORMAT_PATHS	:= ./cmd/ ./middlewares/ ./tsl tsl.go
LINT_PATHS		:= ./ ./cmd/... ./middlewares/... ./tsl/...

rwildcard	:= $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

.SECONDEXPANSION:
.PHONY: all
all: dep format lint release

.PHONY: init
init:
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
	go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
	golangci-lint --install --update

.PHONY: dep
dep:
	dep ensure -v

.PHONY: clean
clean:
	rm -rf build
	rm -rf vendor

.PHONY: lint
lint:
	@command -v golangci-lint >/dev/null 2>&1 || { echo >&2 "golangci-lint is required but not available please follow instructions from https://github.com/golangci/golangci-lint"; exit 1; }
	golangci-lint run --deadline=180s --disable-all --enable=gofmt $(LINT_PATHS)
	golangci-lint run --deadline=180s --disable-all --enable=vet $(LINT_PATHS)
	golangci-lint run --deadline=180s --disable-all --enable=golint $(LINT_PATHS)
	golangci-lint run --deadline=180s --disable-all --enable=ineffassign $(LINT_PATHS)
	golangci-lint run --deadline=180s --disable-all --enable=misspell $(LINT_PATHS)
	golangci-lint run --deadline=180s --disable-all --enable=staticcheck $(LINT_PATHS)

.PHONY: format
format:
	gofmt -w -s $(FORMAT_PATHS)

.PHONY: dev
dev: format lint build

.PHONY: build
build: tsl.go $$(call rwildcard, ./cmd, *.go) $$(call rwildcard, ./core, *.go) $$(call rwildcard, ./tsl, *.go) $$(call rwildcard, ./middlewares, *.go)
	$(CC) $(DFLAGS) -ldflags "$(CFLAGS)" -o $(BUILD_DIR)/tsl tsl.go

.PHONY: release
release: tsl.go $$(call rwildcard, ./cmd, *.go) $$(call rwildcard, ./core, *.go) $$(call rwildcard, ./tsl, *.go) $$(call rwildcard, ./middlewares, *.go)
	$(CC) -ldflags "$(CFLAGS)" -o $(BUILD_DIR)/tsl tsl.go

.PHONY: dist
dist: tsl.go $$(call rwildcard, ./cmd, *.go) $$(call rwildcard, ./core, *.go) $$(call rwildcard, ./tsl, *.go) $$(call rwildcard, ./middlewares, *.go)
	$(CROSS) $(CC) -ldflags "$(CFLAGS) -s -w" -o $(BUILD_DIR)/tsl tsl.go
