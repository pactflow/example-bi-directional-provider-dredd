PACTICIPANT := "pactflow-example-bi-directional-provider-dredd"
GITHUB_REPO := "pactflow/pactflow-example-bi-directional-provider-dredd"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:latest"
GIT_COMMIT:= $(shell git rev-parse HEAD)
GIT_BRANCH:= $(shell git rev-parse --abbrev-ref HEAD)

# Only deploy from master
ifeq ($(GIT_BRANCH), master)
	DEPLOY_TARGET=deploy
else
	DEPLOY_TARGET=no_deploy
endif

all: test

## ====================
## CI tasks
## ====================

ci:
	@if make test; then \
		make publish_success; \
	else \
		make publish_failure; \
	fi; \

create_branch_version:
	PACTICIPANT=${PACTICIPANT} GIT_BRANCH=${GIT_BRANCH} GIT_COMMIT=${GIT_COMMIT} ./scripts/create_branch_version.sh

publish_success: .env create_branch_version 
	@echo "\n========== STAGE: publish contract + results (success) ==========\n"
	npm run test:publish -- true

publish_failure: .env create_branch_version 
	@echo "\n========== STAGE: publish contract + results (failure) ==========\n"
	npm run test:publish -- false

# Run the ci target from a developer machine with the environment variables
# set as if it was on Github Actions.
# Use this for quick feedback when playing around with your workflows.
fake_ci: .env
	@echo "TEST VARIABLES BELOW"
	@echo ${GIT_BRANCH}
	@echo ${GIT_COMMIT}
	@echo ${DEPLOY_TARGET}
	@CI=true \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci; 
	make deploy_target

deploy_target: can_i_deploy $(DEPLOY_TARGET)

## =====================
## Build/test tasks
## =====================

test:
	@echo "\n========== STAGE: test ✅ ==========\n"
	npm run test

## =====================
## Deploy tasks
## =====================

deploy: deploy_app record_deployment

no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy: .env
	@echo "\n========== STAGE: can-i-deploy? 🌉 ==========\n"
	"${PACT_CLI}" broker can-i-deploy --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --to-environment development

deploy_app:
	@echo "\n========== STAGE: deploy 🚀 ==========\n"
	@echo "Deploying to prod"

record_deployment: .env
	@"${PACT_CLI}" broker record_deployment --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --environment development

## =====================
## Pactflow set up tasks
## =====================

## ======================
## Misc
## ======================

.env:
	touch .env

.PHONY: all test clean
