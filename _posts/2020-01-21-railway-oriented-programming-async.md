---
author: Jon Minter
title:  "Asynchronous Functions and the Railway Oriented Programming Pattern"
date:   2020-01-21 09:30:00 -0400
categories:
    - Posts
tags:
    - functional programming
    - railway oriented programming
    - reactive programming
published: false
---
Despite the fact that I have mostly used imperative programming languages throughout my career (though some like JavaScript have the ability to be used in a functional way) I have have always had a fascination with functional programming ever since I took a class on functional programming using the OCaml programing language way, way back when I was in undergraduate school.

I won't pretend to be an expert on functional programming or pretend that I have completely wrapped my head around concepts like functors, monads, or applicatives but there was one programming pattern I was reading about a while ago dubbed "Railway Oriented Programming" by Scott Wlaschin that intrigued me.

So what is "Railway Oriented Programming"? Railway Oriented Programming is a pattern for handling branches in logic in your program in a clean and concise way. Instead of nesting if statements you use the power of function composition and a static type system to chain functions together and allow you to choose which branch of logic to go to next skipping over the remaining functions in the chain without having to use exceptions.

Scott Wlaschin uses the anology of of railway switches to visualize how this control flow pattern works. I think its particularly useful for modeling the error handling for your domain logic. It allows handling of errors in a type safe way and force the user to think about both the happy and not so happy paths of the application logic. It's important to note this isn't meant to be a replacement for exceptions but can be used as a different way to think about and model the control flow of your domain logic.

If you are not familiar with this concept you will probably find it helpful to read these posts first to get some context as Scott Wlaschin can explain the concept better than I can:
- [Railway Oriented Programming - Scott Wlaschin (I highly recommend watching the video of his talk)](https://fsharpforfunandprofit.com/rop/)
- [Against Railway Oriented Programming - Scott Wlaschin](https://fsharpforfunandprofit.com/posts/against-railway-oriented-programming/)

So you've read these articles and you agree that is this is cool idea and want to start using it where it makes sense in your code base. I was attempting to use this pattern with TypeScript recently. This pattern works great if your switch functions are all synchronous and don't need to wait for an HTTP call, file system operation or database query. You simply start with your initial input and pass that input through your switches along the railway. But this is the real world and most of us have to interact with systems outside of our program. I didn't real find much in my search to see how anyone who using this pattern handled that outside of F#.

So lets see what happens when you throw asynchronous functions in the mix.

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
- Encourages us to write small, focused functions and chain them together, these small functions are easier to test
- We can use descriptive names for each function and makes it easy to see what our code is supposed to do by looking at functions that are chained together, our code becomes self documenting
- We can use the type system to remind us to handle the non-happy path and encourage us to handle the output at the end of both paths the exact same way regardless of how we actually got there
- If an exception occurs we know it was truly from something exceptional and we can let that exception bubble up to our main exception handler

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

So how could we solve this? Is there a way to model this so we can handle both async and sync functions and still use this ROP pattern?

Let's think about what's happening when we chain these functions together. When we're working with synchronous functions every time we call True Myth's `andThen` function we pass it a switch function and it applies that function to the current `Result` object we have at the time. When we're working with asynchronous functions we aren't returning an actual `Result` object but a promise that there will be a `Result` object at some point in the future. So we need some way to queue up the functions along our railway and only execute them when the previous function's promise has resolved.

So we can write up a simple helper class that abstracts that logic for us and provides a nice fluent interface. Keeping with our railway analogy we'll call this helper `AsyncRailway`:

{% highlight typescript %}
// Let's create a type alias for a Promise of a Result just to save us some typing
type AsyncResult<S, E> = Promise<Result<S, E>>;
// ...alias type for our async switch functions
type AsyncSwitch<S,E> = (input: S) => AsyncResult<S, E>;
// ...and finally an alias for our synchronous switch functions
type Switch<S, E> = (input: S) => Result<S, E>;

function convertAsync<S, E>(syncSwitch: Switch<S, E>): AsyncSwitch<S, E> {
    return async (input: S) => {
        return Promise.resolve(syncSwitch(input));
    }
}

class AsyncRailway<S,E> {
    private switches: Array<AsyncSwitch<S, E>> = [];
    constructor(private readonly input: Result<S, E>) {}

    static leaveTrainStation<S,E>(input: Result<S, E>) {
        return new AsyncRailway(input);
    }

    andThen(switchFunction: AsyncSwitch<S, E>) {
        this.switches.push(switchFunction);
        return this;
    }

    async arriveAtDestination(): AsyncResult<S, E> {
        return this.switches.reduce(async (previousPromise, nextSwitch) => {
            const previousResult = await previousPromise;
            return previousResult.isOk()
                ? await nextSwitch(previousResult.value)
                : previousResult;
        }, Promise.resolve(this.input));
    }
}
{% endhighlight %}

So with  this helper class we can now do this:

{% highlight typescript %}
await (AsyncRailway
    .leaveTrainStation(Result.ok<User, string>(someUser))
    .andThen(convertAsync(validateUsernameNotEmpty))
    .andThen(convertAsync(validateUsernameNotEmpty))
    .andThen(validateUsernameIsUnqique)
    .arriveAtDestination())
    .match({
        Ok: user => printValidUser(user),
        Err: errMsg => printError(errMsg)
    });
{% endhighlight %}

Awesome that works! But what if our functions are transforming the initial input from one type to another? For example suppose we want to add a function to the chain that saves the user account to our database and returns the inserted user's identifier:

{% highlight typescript %}
...

class SavedUserAccount {
    constructor(readonly newUserId: string) {}
}

async function saveUser(input: User): Promise<Result<SavedUserAccount, string>> {
    // Let's pretend we made a call to our user database to save the user and
    //  this is the new user's user ID
    return Promise.resolve(new SavedUserAccount('ee2dadae-f70f-4cd4-b0a3-0d03d779118f'));
}

...

await (AsyncRailway
    .leaveTrainStation(Result.ok<User, string>(someUser))
    .andThen(convertAsync(validateUsernameNotEmpty))
    .andThen(convertAsync(validateUsernameNotEmpty))
    .andThen(validateUsernameIsUnqique)
    .andThen(saveUser) // Compilation error here because we're returning Result<SavedUserAccount>
    .arriveAtDestination())
    .match({
        Ok: user => printValidUser(user),
        Err: errMsg => printError(errMsg)
    });
{% endhighlight %}

Whoops! This doesn't compile anymore because our `AsyncRailway` class only allows us to collect and use switch functions that act on and return the same type.

So how could we solve this? Lets harness the power of RxJS the reactive extensions framework for JavaScript and create a custom operator that would allow us to acheive this same result and still allow us to transform inputs to a different output type. 

If you aren't familiar with RxJs or reactive programming check out these links for some context:
- [What is Reactive Programming - Andre Stalz](https://gist.github.com/staltz/868e7e9bc2a7b8c1f754)
- [Learn RxJs](https://www.learnrxjs.io/)

Here's an implementation idea using a single custom RxJs operators to allow this:

{% highlight typescript %}
import {
    of,
    OperatorFunction,
    pipe,
} from 'rxjs';
import { flatMap } from 'rxjs/operators';

type AsyncSwitchTransform<I, O, E> = (input: I) => AsyncResult<O, E>;

function asyncAndThen<I, O, E>(
    railwaySwitch: AsyncSwitchTransform<I, O, E>
): OperatorFunction<Result<I, E>, Result<O, E>> {
    return pipe(
        flatMap(x => {
            return x.isOk() ? railwaySwitch(x.value) : of(x as Err<any, E>);
        })
    );
}
{% endhighlight %}

We've managed to do this in just a few lines of code let's break down what it's doing.

First, we define an type alias so we have a shorthand type for defining our switch functions that can optionally transform the input type to a different output type.

And second, we define an RxJs operator by creating a function that returns an `OperatorFunction` that RxJs can use to transform the `Observable`. This function uses the RxJs `pipe` function and uses the `flatMap` operator with a function that will unwrap the `Result` object, check if there was an error and if not pass the value to the next switch function in the railway sequence. However if the `Result` object contains an error then we short circuit and return the `Error`. Almost identical to the promise based version above.

Why use `flatMap` instead of the RxJs `map` operator? Remember since we're working with promises the switch function is returning a promise of a future `Result` object rather than the `Result` object it. So we end up with an observable item that contains a promise of a `Result` and the `flatMap` operator will handle the flattening for us so that at the end of all our operations we end up with an `Observable<Result<User, string>>` instead of `Observable<Promise<Result<User, string>>>`.

So here's how we would use this new operator:

{% highlight typescript %}
const johnPublic = new User('johnqpublic', 'John', 'Public');
of(Result.ok(johnPublic))
    .pipe(
        asyncAndThen(convertAsync(validateUsernameNotEmpty)),
        asyncAndThen(convertAsync(validateUsernameHasValidChars)),
        asyncAndThen(validateUsernameIsUnqique),
        asyncAndThen(saveUser)
    )
    .toPromise()
    .then(result => {
        result.match({
            Ok: user => printSavedUser(user),
            Err: errMsg => printError(errMsg)
        });
    });
{% endhighlight %}

So now that we've defined this operator we can use our railway pattern and use it with functions that transform the input and still have the power of TypeScript's type system to ensure for example we've put our switch functions in the right order and that they can only be used with the types they are defined for.

One other side benefit of using RxJs to do this is that we can not only run our sequence of switch functions on a single item we could use the same sequence of transformations on a stream of multiple items. So for example you could use the same logic to import a batch of users into your user database that you use to create a single user.

So that's it, I hope someone finds this useful or thought provoking. You can see a [complete code example](https://www.github.com/jonminter/railway-oriented-programming-async) on my github.
