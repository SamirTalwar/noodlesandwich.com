If you're new to programming, type systems can be scary. That is, if you know what they are at all.

Fortunately, they're not mandatory. You can write JavaScript perfectly well without knowing <del>anything</del> <ins>much</ins> about types.

But we're not here to talk about what you *need* to know. We're here because knowing more about type systems will help us become better developers.

## It turns out JavaScript has a type system

Fire up your favourite REPL (I recommend just opening your browser's console) and follow along.

*I'll use `>` to denote typing into the REPL; the result, if there is one, will go underneath it.*

    > typeof 3
    'number'
    > typeof 'bananas'
    'string'

So, JavaScript has *types*. In fact, it has a bunch of types. A whole *system* of them. So that's cool. Job done. We can go home now.

BUT WAIT.

There are some limitations:

    > typeof {name: 'Mortimer'}
    'object'
    > typeof {bag: {containing: ['soup']}}
    'object'

That's not very useful. Allow me to explain why.

## Deconstructing the system

Type systems are made of types.

Yes, I can see you're wearing your "mind, blown" face. I am not surprised.

Here's what Wikipedia has to say about types:

> In programming languages, a type system is a set of rules that assigns a property called type to the various constructs of a computer program, such as variables, expressions, functions or modules. These types formalize and enforce the otherwise implicit categories the programmer uses for data structures and components (e.g. "string", "array of float", "function returning boolean").

Well, that's not helpful. Let's try and do better than that.

The *type* of a value tells us what we can do with that value, and what we can't.

Let's take `3` for example. In JavaScript, `3` is a *number*, which means it can do a bunch of things:

  * add itself with another number (`3 + 2 == 5`);
  * subtract (`3 - 5 == -2`);
  * multiply, divide, etc.
  * bit arithmetic (`3 & 5 == 1`, `3 | 6 == 7`, etc.);
  * negate itself (`-3`);
  * convert itself to a string (`(3).toString() == '3'`);
  * with the help of the `Math` library, a number of more complicated operations:
    * finding the power of that number (`Math.pow(3, 2) == 9`),
    * trigonometric functions, such as `sin` and `cos`,
    * logarithms, with the `log` family of functions,
    * and lots more;
  * more functions I didn't think of;
  * and, of course, any function we write that handles numbers.

It also *can't* do a lot of things. Like concatenate with another value. Or iterate through its elements (because it doesn't have any elements). Or tell us its name (because it doesn't have one).

Conversely, strings (such as `'avocado'` or `"Abracadabra!"`) can concatenate, and they can go uppercase, or lowercase, or split themselves. But they can't multiply.

This is all *type* means. So don't get scared when people talk about types; all they're referring to is this big list of things that the value can do.

Hopefully this explains why `typeof` annoyed me earlier. `typeof 3` returns `"number"`, which is great; it tells us what we can do with it. But `typeof {name: 'Mortimer'}` didn't help me at all. It just told me it was an `"object"`, which tells me that it has properties, but doesn't tell me which ones. In other words, I don't know what I can do with that object.

Ideally, my type system would say, "this is an object, and it has one property, `name`, which is a `string`." Then I could make a useful decision about what to do with that object.

There are two main reasons to use a type system:

  1. Type systems allow you to specify the range of possible operations on a value, and query that list later, so that you can't forget what you've got.
  2. A type system can check when you try to do something with a value that it can't do, and tell you.

JavaScript isn't very good at the former, but it doesn't even bother with the latter most of the time: when we try and use the value in the wrong way, it doesn't tell us by throwing an error; it just returns `undefined`. Here's an example:

    > let alice = {secret: 99}
    > alice.name
    undefined
    > alice.jump
    undefined

    > let dazzle = person => `*** ${person.name} ***`
    '*** undefined ***'

It's only if we go further and keep digging that we get that error:

    > alice.name.toUpperCase()
    TypeError: Cannot read property 'toUpperCase' of undefined
    > alice.jump()
    TypeError: alice.jump is not a function

    > let dazzle = person => `*** ${person.name.toUpperCase()} ***`
    > dazzle(alice)
    TypeError: Cannot read property 'toUpperCase' of undefined
        at dazzle (repl:1:45)

Only by attempting to do stuff to `null` or `undefined` can we get JavaScript to tell us we did something wrong with a `TypeError`. And that's not that useful; it tells us that we had an `undefined`, but not where it came from or why. In this case it's pretty obvious, but in larger chunks of code, it may not be so clear why `alice` doesn't have a `name`.

So let's look at some other type systems which allow us to take care of this problem.
