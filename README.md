# Example Provider

[![Build Status](https://travis-ci.com/pactflow/example-collaborative-contracts-provider.svg?branch=master)](https://travis-ci.com/pactflow/example-collaborative-contracts-provider)

This is an example "Product" API Provider, to demonstrate the new bi-directional contract capability of Pactflow (previously referred to as Provider driven contracts, or collaborative contracts). It:

* Is an API written in Express JS
* Has OAS 3.0 spec documenting the API
* Uses Dredd for API testing to check spec compliance

It is using a public tenant on Pactflow, which you can access [here](https://test.pact.dius.com.au) using the credentials `dXfltyFMgNOFZAxr8io9wJ37iUpY42M`/`O5AIZWxelWbLvqMd8PkAVycBJh2Psyg1`. The latest version of the Example Consumer/Example Provider pact is published [here](https://test.pact.dius.com.au/pacts/provider/pactflow-example-collaborative-contracts-provider/consumer/pactflow-example-consumer/latest).

In the following diagram, you can see how the provider testing process works. Starting with our OAS, we use Dredd to verify that all

When we call "can-i-deploy" the cross-contract validation process kicks off on Pactflow, to ensure any consumer consumes a valid subset of the OAS for the provider.

![Provider Test[(docs/provider-scope.png "Provider Test")

When you run the CI pipeline (see below for doing this), the pipeline should perform the following activities (simplified):

![Provider Pipeline[(docs/provider-pipeline.png "Provider Pipeline")

## Pre-requisites

**Software**:

* Tools listed at: https://docs.pactflow.io/docs/workshops/ci-cd/set-up-ci/prerequisites/
* A pactflow.io account with an valid [API token](https://docs.pactflow.io/docs/getting-started/#configuring-your-api-token)

### Environment variables

To be able to run some of the commands locally, you will need to export the following environment variables into your shell:

* `PACT_BROKER_TOKEN`: a valid [API token](https://docs.pactflow.io/docs/getting-started/#configuring-your-api-token) for Pactflow
* `PACT_BROKER_BASE_URL`: a fully qualified domain name with protocol to your pact broker e.g. https://testdemo.pactflow.io

## Usage

* `make test` - run the dredd testing suite
* `make fake_ci` - run the CI process, but locally

## Warning - here be dragons 🐉

* You must ensure `additionalProperties` in your OAS is set to `false` on any response body, to ensure a consumer won't get false positives if they add a new field that isn't actually part of the spec (see
https://bitbucket.org/atlassian/swagger-mock-validator/issues/84/test-incorrectly-passes-when-mock-expects for an interesting read on why this is necessary. TL;DR - it's JSON Schemas fault)
*  you are responsible for ensuring sufficient OAS coverage. To highlight this point, in our example, we do _not_ test the 404 case on the provider, but the consumer has a pact for it and it's tests still pass! _NOTE: We plan to address this problem in the future_
* _implementing_ a spec is not the same as being _compatible_ with a spec. Most tools only tell you that what you’re doing is _not incompatible_ with the spec. _NOTE: We plan to address this problem in the future_
