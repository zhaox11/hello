#
### Copyright(c) 2002-2023, Dell Technologies.
#
#
OS := $(shell uname)
# From OBS 
PRODUCT_VERSION      := 0.1
GIT_BRANCH           := $(shell git branch -v | grep '^*' | awk '{print $$2}' || echo 'NO_BRANCH')
GIT_COMMIT_COUNT     := $(shell git rev-list HEAD --count)
GIT_COMMIT_SHORT_ID  := $(shell git rev-parse --short HEAD)
BUILD_PLAT           := $(shell uname -s | tr '[:upper:]' '[:lower:]')
VERSION              ?= ${PRODUCT_VERSION}-${GIT_COMMIT_COUNT}.${GIT_COMMIT_SHORT_ID}
LDFLAGS              := -static
GO_LDFLAGS           += -extldflags \"${LDFLAGS}\"
GO_LDFLAGS           += -X main.Version=$(BUILD_VERSION)
GO_LDFLAGS           += -X main.BuildDate=$(shell date +'%Y-%m-%dT%H:%M:%SZ')
GO_LDFLAGS           += -X main.GitCommit=$(COMMIT)
GO_LDFLAGS           += -X main.GitTreeState=$(if $(shell git status --porcelain),dirty,clean)
GO_LDFLAGS           += -X main.VersionBuild=$(VERSION)

GIT_USER             := $(shell git branch -v | grep '^*' | awk '{print $$2}' | awk 'BEGIN{FS="/"}{ print $$2 }' || echo "NO_USER")
JIRA_ID              := $(shell git branch -v | grep '^*' | awk '{print $$2}' | awk 'BEGIN{FS="/"}{ print $$3 }' | awk 'BEGIN{FS="-"}{ print $$1"-"$$2 }' || echo "NO_JIRA")
CI_SERVICE           := http://powerservice.datadomain.com/jenkins/job/dev/job/UoM/job/Santorini/job/
CI_CREATE_JOB        := $(CI_SERVICE)/$(GIT_USER)/createItem?name=$(JIRA_ID)
CI_JOB               := $(CI_SERVICE)/$(GIT_USER)/job/$(JIRA_ID)
CI_BUILD_JOB         := $(CI_JOB)/build

BUILD_LEVEL ?= nightly
PLAT ?= cluster
COMMON_SRCTOP = $(SRCTOP)/$(PLAT)/common
HELLO_SRCTOP = $(SRCTOP)/$(PLAT)/hello
HELLO_OUTPUT = $(HELLO_SRCTOP)/build.out/$(BUILD_LEVEL)

### custom variables that could be ommited
GOPRIVATE_PART  :=
#GOPROXY_PART    := GOPROXY=https://proxy.golang.org,direct

### go env vars
GO_ENV_VARS     := GO111MODULE=on ${GOPRIVATE_PART} ${GOPROXY_PART}

GOROOT := /auto/home/lsbuild/desktop-800003/go.1.19/usr/lib64/go/1.19/
ALT_GO := $(GOROOT)/bin/go
GOCMD := $(CGO_LDFLAGS) $(CGO_CXXFLAGS) $(ALT_GO) build -ldflags "$(GO_LDFLAGS)" -v
OPERATOR_SDK_VERSION ?= v1.32.0
IMG ?= controller:latest
ENVTEST_K8S_VERSION = 1.26.0

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all
all: build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: build
build:
	@echo "GIT_USER=$(GIT_USER) GIT_BRANCH=$(GIT_BRANCH) JIRA_ID=$(JIRA_ID)"
	$(GOCMD) -o hello_main main.go

.PHONY: clean
clean:
	rm -rf $(HELLO_SRCTOP)/build.out

.PHONY: test
test:
	@echo "run test"
	go version
	go test -v ./test

.PHONY: create-pipeline
create-pipeline:
	@echo "create pipeline $(JIRA_ID)"
	python3 ../gen_ci_config.py $(GIT_BRANCH) > ./pipeline-config.xml
	curl -X POST $(CI_CREATE_JOB)      --user zhaox11:119ac05fa3bd417bc3b107462de62d6724     --header "Content-Type: application/xml" --data-binary @./pipeline-config.xml

.PHONY: build-pipeline
build-pipeline:
	@echo "build pipeline $(JIRA_ID)"
	curl -X POST $(CI_BUILD_JOB) --user zhaox11:119ac05fa3bd417bc3b107462de62d6724

.PHONY: delete-pipeline
delete-pipeline:
	@echo "delete pipeline $(JIRA_ID)"
	curl -X DELETE $(CI_JOB)/ --user zhaox11:119ac05fa3bd417bc3b107462de62d6724
