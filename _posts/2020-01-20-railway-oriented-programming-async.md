---
author: Jon Minter
title:  "Asynchronous Functions in the Railway Oriented Programming Model"
date:   2020-01-20 09:30:00 -0400
categories:
    - Posts
tags:
    - functional programming
    - railway oriented programming
    - concurrency
---
Despite the fact that I have used imperative programming languages throughout my career (though some like JavaScript have the ability to be used in a functional way) I have have always had a fascination with functional programming ever since I took a class on functional programming using the OCaml programing language back when I was in undergraduate school.

Pure functional languages are built on top of lambda calculus and give you guarantess about program correctness that can be proved mathematically.

I won't pretend to be an expert on functional programming or pretend that I have completely wrapped my head around concepts like functors, monads, or applicatives but there was one topic I was reading about a while ago dubbed "Railway Oriented Programming" by Scott Wlaschin that intrigued me.

So what is "Railway Oriented Programming"? Railway Oriented Programming is a model for handling branches in logic in your program in a clean and concise way. Scott Wlaschin uses the anology of of railway switches to visualize how this control flow pattern works. I think its particularly useful for error handling. It allows handling of errors in a type safe way and force the user to think about both the happy and sad paths of the application logic.

I'll go into more depth about what that means in a bit. For this articles I'll be using TypeScript for examples.

Think about how you would typically handle errors with an imperative programming style. Let's take an example of validating a user name. Let's say our validate function returns a boolean true if the provided user name is valid and throws an exception if its invalid with an error message explaining what was invalid.

So what kinds of validations might we have? To start with we'd probably want to check that the string provided is a non-empty string.

{% highlight typescript %}
function validateUsername(username: string): boolean {
    if (username.length === 0) {
        throw Error('Username cannot be empty!');
    }
    return true;
}
{% endhighlight %}

But that's probably not sufficient validation for our application. We might also want to check that the username has is a restricted character set say any letter or number plus underscores and dashs but no other characters.

{% highlight typescript %}
function validateUsername(username: string): boolean {
    if (username.length === 0) {
        throw Error('Username cannot be empty!');
    } else {

    }
    return true;
}
{% endhighlight %}

