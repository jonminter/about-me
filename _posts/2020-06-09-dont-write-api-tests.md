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
published: false
---
Stop writing API tests. Now you might say, well don't we need tests to know our software works properly? And the answer is of course yes. So lets rephrase that in less sensational terms. Stop writing so many example based tests. Instead let your computer generate tests cases. You'll spend less effort, catch more edge cases, and have better confidence in your API that you are testing.

The typical strategy for writing automated tests is for the developer to try to think of a set of example test cases that cover the functionality of the system under test. Being human they're almost guaranteed to to miss some pertinent scenarios. In addition as changes are made they have to keep the tests up to date as the specifications for the API evolve. Surely there is an easier way to manage automated API tests. I am going to show you one way in this article.

Many of us maintain machine readable specifications of our APIs. One type of machine readable specification you are probably familiar with is the OpenAPI specification (formerly known as Swagger). These specifications act as documentation to a developer or end user and can show what routes are defined by the API and the schema of valid inputs and outputs of the API. Since an OpenAPI specification is a machine readable document in JSON format this documentation is usable not just by developers but can be used by a machine for various purposes. You may have used tools to do things like generate client code to use to interact with an API or maybe you've even used tools that generate boilerplate code to build a server that acts as a REST API based on the given OpenAPI specification.

There's an additional use for this OpenAPI specification that I'd wager not many developers have considered. You can use it to generate tests cases from the specification. Think about it, this specification tells us all of the available routes, what consititutes valid input and even tells us what the output should look like when we receive a response from the API. These are some of the exact things we tend to test for when writing end-to-end API tests.

So let's take a look at how we might use a few pre-existing tools/libraries and build something that will generate our test cases for us and allow us to comprehensively test our API with very little effort.

### Generative vs Example Testing

Before we get started writing code I am introducing a concept some of you may be familiar with: Property Based Testing (PBT). With property based testing you do not need to write out individual example based test cases. The testing framework can be configured to generate a large number of randomized inputs for your system under test and perform assertions that should be true for any input given to the system under test. These rules or invariants that never change regardless of the input supplied are referred to as properties, hence property based testing.  If you are not familiar with the concept or need a refresher you might find it helpful to watch the below video and/or take a look at the following article for some context first:

- [Don't Write Tests - Talk by John Hughes (Creator of QuickCheck the first PBT framework)](https://www.youtube.com/watch?v=hXnS_Xjwk2Y)
- [An Introduction to Property Based Testing - Scott Wlaschin](https://fsharpforfunandprofit.com/posts/property-based-testing/)

Property based testing can be implemented in a couple of different ways depending on your use case. One way is stateless testing where we generate a lot of random input and perform a single operation against our system under test and validate that whatever property we are testing holds true. A second way we do property based tests is stateful or model based testing. I think this is one of the more powerful and underused features of property based testing. Stateful testing allows us to define a model that represents our system under test and define the different operations that can performed on the system under test. And not only can the testing framework provide randomized input for each operation it can generate a random sequence of operations to perform as well. Note that not all property based testing frameworks provide stateful testing but the one we will be using `fast-check` does provide this feature.

So how is this stateful property-based testing useful to us? Let's assume for example our REST API implements CRUD (create, read, update, delete) for one or more resources. We can have our property based testing framework generate many randomized sequences of operations. One sequence might be just to run the `create` operation, another sequence might be `create` -> `read` -> `update` -> `delete`, and so on. The framework can generate as many of these sequences as we want. What's more is that we can keep state in between each operation. So a `create` operation creates a new resource with our API and we can parse the response and get the ID of the new resource that we can use to perform the remaining `read`, `update`, `delete` operations. This allows us to generate tests cases that can fully execute our API without needing any special setup or hooks (to be fair for non-trivial APIs you still may need some setup or hooks but this reduces the need for these).

There are some existing API testing tools which use non-stateful property based testing to do what is analagous to fuzz testing your API. Verifying that you get a successful response for any valid input or even generating invalid input to verify the API returns an appropriate error code. I have not found to date any API testing tool that utilizes stateful property based testing. However, during my research for generative API testing tools I did come across a couple of research papers that explored generative testing using OpenAPI specifications these were part of the inspiration for this article:

- [QuickREST: Property-based Test Generation of OpenAPI-Described RESTful APIs by Stefan Karlsson, Adnan Čaušević, Daniel Sundmark](https://arxiv.org/pdf/1912.09686.pdf)
- [REST-ler: Automatic Intelligent REST API Fuzzing by Vaggelis Atlidakis, Patrice Godefroid, Marina Polishchuk](https://www.microsoft.com/en-us/research/uploads/prod/2018/04/restler.pdf)


### Let's write some code!

So let's start writing some code to explore this idea and create a proof-of-concept. I'm going to use Typescript to implement this for a couple of different reasons. 1) The project I'm currently working on at work is a Typescript project so there's less code switching needed for me 2) We'll be working with an example REST API that consumes and produces JSON. Typescript is a superset of Javascript and Javascript natively handles JSON making it easy to work with. 3) There was already an implementation of JSON Schema generator for the `fast-check` PBT library. As you'll see later this comes in handy and makes it simple for us to generate sample inputs from our OpenAPI spec as OpenAPI object schemas are very similar to JSON Schema object schemas.

One of the most difficult things about property based testing is determining what properties/invariants you want to verify hold true for all test cases. For testing our REST API the types of properties that we would probably want to test are:
- Did we get a success HTTP status code for valid inputs?
- Is the response body valid according to our Open API spec?
- If we provide known invalid input we should receive a 400 http status code

Let's implement a simple CRUD REST API. This is the OpenAPI specification that we are going to be working with:

### Conclusion

So I've shown in this article some of the benefits of utilizing generative testing strategies in addition to example based testing strategies when testing REST APIs. And we've walked through creating a proof-of-concept API testing tool that uses OpenAPI specifications to automate generating test cases for testing a RESTful CRUD API.

[You can find a complete code example here on my GitHub.]()

Below are some existing API testing tools you may be interested in that can jump start your effort to write less, and generate more API tests:
- [Schemathesis](https://github.com/kiwicom/schemathesis) - Property based API testing tool built on top of python's [hypothesis](https://hypothesis.readthedocs.io/en/latest/) property based testing framework
- [Dredd](https://dredd.org/en/latest/) - Language agnostic API testing tool that uses API Blueprint or OpenAPI specifications to generate test cases
- [CATS](https://github.com/Endava/cats) - Automated fuzz testing using OpenAPI specification

These tools won't allow you to do the type of stateful testing we did in our example above but Schemathesis and CATS will both allow you to run any number of randomized generated example input against your API. Dredd on the other hand uses examples from the API specification to run tests. Schemathesis and CATS would both function great as fairly exhaustive tests for your input validation. And all three provide their own ways to provide for inputs that cannot be randomized well. For example testing a PUT operation to replace an existing resource you could pre-seed some data and provide the seed data resource ID to the testing tool to use for a PUT operation.

Hope this article was useful for someone or introduced some new ideas/concepts.