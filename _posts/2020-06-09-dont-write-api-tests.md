---
author: Jon Minter
title:  "Stop writing API Tests"
date:   2020-06-09 10:23:00 -0400
categories:
    - Posts
tags:
    - apis
    - restful apis
    - openapi
    - automated testing
    - property based testing
published: true
---
I'm going to say something that may sound controversial when taken at face value. Stop writing API tests.

Lets rephrase that in less clickbaity terms. Stop writing so many example based tests. Instead let your computer generate tests cases. You'll spend less effort, catch more edge cases, and have better confidence in your API you are testing.

With the typical strategy for writing automated tests the developer tries to think of a set of example test cases that cover the functionality of the system under test. Being human they're almost guaranteed to to miss some scenarios. In addition as changes are made they have to keep the tests up to date as the specifications change.

Many of us maintain machine readable specifications of our APIs of which the OpenAPI specification is very widely used. What if we could use that specification to generate test cases and have a comprehensive test suite without having to write out the individual examples?

Some of you may be familiar with a testing strategy called Propert Based Testing. With property based testing you tell your testing framework how to generate valid inputs for your system under test and the framework can generate tons of randomized inputs and perform assertions that should be true for any input given to the system under test.

Since we have an OpenAPI spec for our API we have a description of all valid input for our API routes. We can use this OpenAPI spec along with a property based testing framework and a few other tools and build a tool that can automate generating test cases for our API.

One of the most difficult things about propert based testing is determining what properties you want to verify hold true for all test cases. For testing our REST API the types of properties that we would probably want to test are:
- Did we get the HTTP status code we expected? i.e. for any GET request we expect a 200, for POST that creates a new resource a 201, for DELETE a 200, etc.
- Is the response body valid according to our Open API spec?
- If we provide known invalid input we should receive a 400 http status code

Let's use as an example a simple CRUD (create, read, update, delete) API. This is a pretty common workflow for REST APIs where we need to be able to create, read, update and delete one or more resources via our API.

Some API testing tools you may be interested in that help you write less, and generate more API tests:
- [Schemathesis](https://github.com/kiwicom/schemathesis) - Property based API testing tool built on top of python's [hypothesis](https://hypothesis.readthedocs.io/en/latest/) property based testing framework
- [Dredd](https://dredd.org/en/latest/) - Language agnostic API testing tool that uses API Blueprint or OpenAPI specifications to generate test cases
- [CATS](https://github.com/Endava/cats) - Automated fuzz testing using OpenAPI specification
