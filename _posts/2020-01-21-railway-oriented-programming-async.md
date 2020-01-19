---
author: Jon Minter
title:  "Asynchronous Functions and the Railway Oriented Programming Pattern"
date:   2020-01-21 09:30:00 -0400
categories:
    - Posts
tags:
    - functional programming
    - railway oriented programming
published: false
---
Despite the fact that I have mostly used imperative programming languages throughout my career (though some like JavaScript have the ability to be used in a functional way) I have have always had a fascination with functional programming ever since I took a class on functional programming using the OCaml programing language back when I was in undergraduate school.

I won't pretend to be an expert on functional programming or pretend that I have completely wrapped my head around concepts like functors, monads, or applicatives but there was one programming pattern I was reading about a while ago dubbed "Railway Oriented Programming" by Scott Wlaschin that intrigued me.

So what is "Railway Oriented Programming"? Railway Oriented Programming is a pattern for handling branches in logic in your program in a clean and concise way. Instead of nesting if statements you use the power of function composition and a static type system to chain functions together and allow you to choose which branch of logic to go to next skipping over the remaining functions in the chain without having to use exceptions.

Scott Wlaschin uses the anology of of railway switches to visualize how this control flow pattern works. I think its particularly useful for modeling the error handling for your domain logic. It allows handling of errors in a type safe way and force the user to think about both the happy and not so happy paths of the application logic. It's important to note this isn't meant to be a replacement for exceptions but can be used as a different way to think about and model the control flow of your domain logic.

If you are not familiar with this concept you will probably find it helpful to read these posts first to get some context as Scott Wlaschin can explain the concept better than I can:
- [Railway Oriented Programming - Scott Wlaschin (I highly recommend watching the video of his talk)](https://fsharpforfunandprofit.com/rop/)
- [Against Railway Oriented Programming - Scott Wlaschin](https://fsharpforfunandprofit.com/posts/against-railway-oriented-programming/)

So you've read these articles and you agree that is this is cool idea and want to start using it where it makes sense in your code base. I was attempting to use this pattern with TypeScript recently. This pattern works great if your switch functions are all synchronous and don't need to wait for an HTTP call, file system operation or database query. You simply start with your initial input and pass that input through your switches along the railway. But lets see what happens when you throw asynchronous functions in the mix.

Let's use as an example validating user input for an API. We'll use the functional programming helper library [True Myth](https://github.com/true-myth/true-myth) for demonstration purposes as it includes an implementation of the Result type and helper functions to wrap/unwrap values and chain together function calls.

Let's consider this example:
{% highlight typescript %}
import { Result, Ok, Err } from 'true-myth';

class User {
    constructor(
        readonly username: string,
        readonly firstName: string,
        readonly lastName: string,
    ) {}
}

function validateUsernameNotEmpty(input: User): Result<User, string> {
    if (input.username.length === 0) {
        return Result.err('Username cannot be empty!');
    }
    return Result.ok(input);
}

function validateUsernameHasValidChars(input: User): Result<User, string> {
    if (!input.username.matches(/^[A-Za-z0-9_-]$/)) {
        return Result.err('Username must only contain alphanumeric chars and dashes/underscores');
    }
    return Result.ok(input);
}

function printValidUser(input: User) {
    console.log('User is valid: ', input);
}

function printError(errorMessage: string) {
    console.log('User is invalid: ', errorMessage);
}

const newUser = User('', 'Jon', 'Minter');
Result.ok(newUser)
    .andThen(validateUsernameNotEmpty)
    .andThen(validateUsernameHasValidChars)
    .match({
        Ok: user => printValidUser(user),
        Err: errorMsg => printError(errorMsg),
    });
{% endhighlight %}

We can see how this pattern might be useful for a few reasons:
- Allows us to write small, focused functions to handle different validations and compose then together
- These small functions are easier to test
- We can use descriptive names for each function and makes it easy to see what our code is supposed to do by looking at functions that are chained together, our code becomes self documenting

So this is all well and good but what if for example we needed to validate that the username isn't in use by another user? We'd probably have to make a call to an API or run a query against a database to check if the user name is unique. And that call is going to be an asynchronous call that returns a promise. Why is this an issue? Let's consider this addition to our code:

{% highlight typescript %}
...

async function validateUsernameIsUnique(input: User): Promise<Result<User, string>> {
    const userCount = await getCountOfUsersWithUsername(input.username);
    if (userCount !== 0) {
        return Result.err('Username is not unique!');
    }
    return Result.ok(input);
}

...

Result.ok(newUser)
    .andThen(validateUsernameNotEmpty)
    .andThen(validateUsernameHasValidChars)
    .andThen(validateUsernameIsUnique)
    .match({
        Ok: user => printValidUser(user),
        Err: errorMsg => printError(errorMsg),
    });
{% endhighlight %}

So what's the problem here? Remember when we create an async function in JavaScript this is syntactic sugar for converting the function into a function that returns a promise. So if you tried compile this code it would fail compilation since it no longer returns `Result<User, String>` but `Promise<Result<User, String>>` so it cannot be included in the chain of functions.

So you might say why not just use promises instead of this Result type? Well we could but since a promise doesn't enforce a failure type the TypeScript compiler can only guarantee the types along the happy path and not the failure path. A promise failure is just _some_ error type, it could be a string,  it could be an Error object, it could be a number, anything.

Another alternative is use the Result type and then every time we get to a point where we need to perform an async operation switch to using promises and then back to our ROP pattern.

Example:
{% highlight typescript %}
...

async function validateUsernameIsUnique(input: User): Promise<Result<User, string>> {
    const userCount = await getCountOfUsersWithUsername(input.username);
    if (userCount !== 0) {
        //There is another user with this username
        return Result.err('Username is not unique!');
    }
    return Result.ok(input);
}

...

async function doValidation(newUser: User) {
    let validationResult = Result.ok(newUser)
        .andThen(validateUsernameNotEmpty)
        .andThen(validateUsernameHasValidChars);

    if (validationResult.isOk()) {
        validationResult = await validateUsernameIsUnique(validationResult.value);
    }
    validationResult
        .match({
            Ok: user => printValidUser(user),
            Err: errorMsg => printError(errorMsg),
        });
}
{% endhighlight %}

This works but it's messy and makes us use a different pattern for synchronous vs asynchronous logic. And this is a fairly simple contrived example imagine trying to maintain a large codebase having to do this switching between sync/async logic. We don't have our clean railway pattern anymore.

Also what if we wanted to have the ability to collect a list of functions to chain together at runtime and some or all of those function are asyncronous? We aren't able to do that either.

{% highlight typescript %}
const validators = [
    validateUsernameNotEmpty,
    validateUsernameHasValidChars,
    validateUsernameIsUnique,
];

validators.reduce((result, validator) => {
    return result.andThen(validator); // Oops can't do this if one of these return a Promise
}, Result.ok(input));
{% endhighlight %}

{% highlight typescript %}
...

async function validateUsernameIsUnique(input: User): Promise<Result<User, string>> {
    const userCount = await getCountOfUsersWithUsername(input.username);
    if (userCount !== 0) {
        //There is another user with this username
        return Result.err('Username is not unique!');
    }
    return Result.ok(input);
}

...

async function doValidation(newUser: User) {
    let validationResult = Result.ok(newUser)
        .andThen(validateUsernameNotEmpty)
        .andThen(validateUsernameHasValidChars);

    if (validationResult.isOk()) {
        validationResult = await validateUsernameIsUnique(validationResult.value);
    }
    return validationResult;
}

doValidation(newUser)
    .match({
        Ok: user => printValidUser(user),
        Err: errorMsg => printError(errorMsg),
    });
{% endhighlight %}


So how could we solve this? Is there a way to model this so we can handle both async and sync functions and still use this ROP pattern? Lets harness the power of RxJS the reactive extensions framework for JavaScript. 

Here's an implementation idea using custom RxJs operators to allow this:


You can see a [complete code example](https://www.github.com/jonminter/railway-oriented-programming-async) on my github.
