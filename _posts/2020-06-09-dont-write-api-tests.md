---
author: Jon Minter
title:  "Don't Write API Tests"
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
Stop writing API tests. Now you might say we need tests to know our software works properly and I would agree. So lets rephrase that in less clickbaity terms. Stop writing so many example based tests. Instead let your computer generate tests cases. You'll spend less effort, catch more edge cases, and have better confidence in your API that you are testing.

The typical strategy for writing automated tests is for the developer to try to think of a set of example test cases that cover the functionality of the system under test. Being human they're almost guaranteed to to miss some pertinent scenarios. In addition as changes are made they have to keep the tests up to date as the specifications for the API evolve. Surely there is a better way to manage automated API tests. Turns out there are better ways and I am going to show you one way in this article.

Many of us maintain machine readable specifications of our APIs. One type of machine readable specification you are probably familiar with is the OpenAPI specification (formerly known as Swagger). These specifications act as documentation to a developer or end user and can show what routes are defined by the API and the schema of valid inputs and outputs of the API. Since an OpenAPI specification is a machine readable document in JSON format this documentation is usable not just by developers and other end users but can be used by a machine for various purposes. You may have used tools to do things like generate client code to use to interact with an API or maybe you've even used tools that generate boilerplate code to build a server that acts as a REST API based on the given OpenAPI specification.

There's an additional use for this OpenAPI specification that I'd wager not many developers are familiar with. You can use it to generate tests cases from the specification. Think about it, this specification tells us all of the available routes, what consititutes valid input and even tells us what the output should look like when we receive a response from the API. These are some of the exact things we tend to test for when writing end-to-end API tests.

So let's take a look at how we might use a few pre-existing tools/libraries and build something that will generate our test cases for us.

Some of you may be familiar with a testing strategy called Propert Based Testing (PBT). With property based testing you tell your testing framework how to generate valid inputs for your system under test and the framework can generate a large number of randomized inputs and perform assertions that should be true for any input given to the system under test. If you are not familiar with the concept or need a refresher you might find it helpful to watch the below video and/or take a look at the following article for some context first:

- [Don't Write Tests - Talk by John Hughes (Creator of QuickCheck the first PBT framework)](https://www.youtube.com/watch?v=hXnS_Xjwk2Y)
- [An Introduction to Property Based Testing - Scott Wlaschin](https://fsharpforfunandprofit.com/posts/property-based-testing/)

Since we have an OpenAPI spec for our API we have a description of all valid input for our API routes. We can use this OpenAPI spec along with a property based testing framework and a few other libraries and build a tool that can automate generating test cases for our API.

One of the most difficult things about propert based testing is determining what properties you want to verify hold true for all test cases. For testing our REST API the types of properties that we would probably want to test are:
- Did we get the HTTP status code we expected? i.e. for any GET request we expect a 200, for POST that creates a new resource a 201, for DELETE a 200, etc.
- Is the response body valid according to our Open API spec?
- If we provide known invalid input we should receive a 400 http status code

Let's use as an example a simple CRUD (create, read, update, delete) API. This is a pretty common workflow for REST APIs where we need to be able to create, read, update and delete one or more resources via our API.

Some existing API testing tools you may be interested in that can help you started with writing less, and generating more API tests:
- [Schemathesis](https://github.com/kiwicom/schemathesis) - Property based API testing tool built on top of python's [hypothesis](https://hypothesis.readthedocs.io/en/latest/) property based testing framework
- [Dredd](https://dredd.org/en/latest/) - Language agnostic API testing tool that uses API Blueprint or OpenAPI specifications to generate test cases
- [CATS](https://github.com/Endava/cats) - Automated fuzz testing using OpenAPI specification

These tools won't allow you to do the type of stateful testing we did in our example above but Schemathesis and CATS will both allow you to run any number of randomized generated example input against your API. Dredd on the other hand uses examples from the API specification to run tests. Schemathesis and CATS would both function great as fairly exhaustive tests for your input validation. And all three provide their own ways to provide for inputs that cannot be randomized well. For example testing a PUT operation to replace an existing resource you could pre-seed some data and provide the seed data resource ID to the testing tool to use for a PUT operation.

---
Footnotes:
- <a name="myfootnote1">1</a>: Footnote content goes here