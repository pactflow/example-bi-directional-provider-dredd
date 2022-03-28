PACTICIPANT := "pactflow-example-provider-dredd"
GITHUB_REPO := "pactflow/pactflow-example-provider-dredd"
PACT_CHANGED_WEBHOOK_UUID := "c76b601e-d66a-4eb1-88a4-6ebc50c0df8b"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:latest"

# Only deploy from master
ifeq ($(GIT_BRANCH),master)
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
		make publish_and_deploy; \
	else \
		make publish_failure; \
	fi; \

publish_and_deploy: publish_contract can_i_deploy $(DEPLOY_TARGET)

tag_as_dev:
	@"${PACT_CLI}" broker create-version-tag \
	  --pacticipant ${PACTICIPANT} \
	  --version ${GIT_COMMIT} \
		--auto-create-version \
	  --tag master

publish_contract: .env tag_as_dev
	@echo "\n========== STAGE: publish contract + results (success) ==========\n"
	npm run test:publish -- true

publish_failure: .env tag_as_dev
	@echo "\n========== STAGE: publish contract + results (failure) ==========\n"
	npm run test:publish -- false

# Run the ci target from a developer machine with the environment variables
# set as if it was on Github Actions.
# Use this for quick feedback when playing around with your workflows.
fake_ci: .env
	@CI=true \
	GIT_COMMIT=`git rev-parse --short HEAD`+`date +%s` \
	GIT_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci

ci_webhook: .env
	npm run test:pact

fake_ci_webhook:
	CI=true \
	GIT_COMMIT=`git rev-parse --short HEAD`+`date +%s` \
	GIT_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci_webhook

## =====================
## Build/test tasks
## =====================

test: .env
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
	"${PACT_CLI}" broker can-i-deploy --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --to-environment production

deploy_app:
	@echo "\n========== STAGE: deploy 🚀 ==========\n"
	@echo "Deploying to prod"

record_deployment: .env
	@"${PACT_CLI}" broker record_deployment --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --environment production

## =====================
## Pactflow set up tasks
## =====================

# export the GITHUB_TOKEN environment variable before running this
create_github_token_secret:
	curl -v -X POST ${PACT_BROKER_BASE_URL}/secrets \
	-H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
	-H "Content-Type: application/json" \
	-H "Accept: application/hal+json" \
	-d  "{\"name\":\"githubToken\",\"description\":\"Github token\",\"value\":\"${GITHUB_TOKEN}\"}"

# NOTE: the github token secret must be created (either through the UI or using the
# `create_travis_token_secret` target) before the webhook is invoked.
create_or_update_pact_changed_webhook:
	"${PACT_CLI}" \
	  broker create-or-update-webhook \
	  "https://api.github.com/repos/${GITHUB_REPO}/dispatches" \
	  --header 'Content-Type: application/json' 'Accept: application/vnd.github.everest-preview+json' 'Authorization: Bearer $${user.githubToken}' \
	  --request POST \
	  --data '{ "event_type": "pact_changed", "client_payload": { "pact_url": "$${pactbroker.pactUrl}" } }' \
	  --uuid ${PACT_CHANGED_WEBHOOK_UUID} \
	  --consumer ${PACTICIPANT} \
	  --contract-content-changed \
	  --description "Pact content changed for ${PACTICIPANT}"

test_pact_changed_webhook:
	@curl -v -X POST ${PACT_BROKER_BASE_URL}/webhooks/${PACT_CHANGED_WEBHOOK_UUID}/execute -H "Authorization: Bearer ${PACT_BROKER_TOKEN}"

## ======================
## Misc
## ======================

.env:
	touch .env

publish_contract1: .env 
	@echo "\n========== STAGE: publish contract + results (success) ==========\n"
	OPEN_API_FILENAME=products.yml PACT_PROVIDER=FOO1 GIT_COMMIT=FOO1 npm run test:publish -- true


publish_contract2: .env 
	@echo "\n========== STAGE: publish contract + results (success) ==========\n"
	OPEN_API_FILENAME=products2.yml PACT_PROVIDER=FOO2 GIT_COMMIT=FOO2 npm run test:publish -- true
