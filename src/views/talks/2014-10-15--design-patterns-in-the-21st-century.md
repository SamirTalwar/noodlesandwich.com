## Introduction

### Who are you?

This is me.

```
public final class λs {
    λ Identity = x -> x;

    λ True = x -> y -> x;
    λ False = x -> y -> y;

    λ Zero = f -> x -> x;
    λ Succ = n -> f -> x -> f.$(n.$(f).$(x));
    λ Pred = n -> f -> x ->
        n.$(g -> h -> h.$(g.$(f))).$(ignored -> x).$(u -> u);
    λ IsZero = f -> f.$(x -> False).$(True);

    λ Y = f ->
        λ(x -> f.$(x.$(x)))
            .$(x -> f.$(x.$(x)));
    λ Z = f ->
        λ(x -> f.$(y -> x.$(x).$(y)))
            .$(x -> f.$(y -> x.$(x).$(y)));

    ...
}
```

I do things like that for fun. You can see the full code as part of my [FizzBuzz project](https://github.com/SamirTalwar/FizzBuzz), inspired by Tom Stuart's talk, [Programming with Nothing](http://experthuman.com/programming-with-nothing).

### What do you want from me?

I want you to stop using design patterns.

### Um…

OK, let me rephrase that.

I want you to stop using design patterns like it's *1999*.

## This is a book.

<p style="text-align: center;"><img src="https://assets.noodlesandwich.com/talks/design-patterns-in-the-21st-century/design-patterns.jpg" alt="Design Patterns, by Gamma, Helm, Johnson and Vlissides" style="max-width: 50%;"/></p>

*Design Patterns* was a book by the "Gang of Four", first published very nearly 20 years ago (at the time of writing this essay), which attempted to canonicalise and formalise the tools that many experienced software developers and designers found themselves using over and over again.

The originator of the concept (and the term "design pattern") was Christopher Alexander, who wasn't a software developer at all. Alexander was an architect who came up with the idea of rigorously documenting common problems in design with their potential solutions.

> The elements of this language are entities called patterns. Each pattern describes a problem that occurs over and over again in our environment, and then describes the core of the solution to that problem, in such a way that you can use this solution a million times over, without ever doing it the same way twice. <cite>— Christopher Alexander</cite>

Alexander, and the Gang of Four after him, did more than just document solutions to common problems in their respective universes. By naming these patterns and providing a good starting point, they hoped to provide a consistent *language*, as well as providing these tools up front so that even novices might benefit from them.

## And now, an aside, on functional programming.

Functional programming is all about <em><del>functions</del> <ins>values</ins></em>.

Values like this:

```
int courses = 3;
```

But also like this:

```
Course dessert = prepareCake.madeOf(chocolate);
```

And like this:

```
Preparation prepareCake = new Preparation() {
    @Override
    public Course madeOf(Ingredient deliciousIngredient) {
        return new CakeMix(eggs, butter, sugar)
                .combinedWith(deliciousIngredient);
    }
};
```

Preparation looks like this:

```
@FunctionalInterface
interface Preparation {
    Course madeOf(Ingredient deliciousIngredient);
}
```

So of course, the `prepareCake` object could also be written like this.

```
Preparation prepareCake =
    deliciousIngredient ->
        new CakeMix(eggs, butter, sugar)
            .combinedWith(deliciousIngredient);
```

Because `Preparation` is an interface with a **Single Abstract Method**, any lambda with the same type signature as `Preparation`'s method signature can be assigned to an object of type `Preparation`. This means that `Preparation` is a **functional interface**.

We can go one further. Let's extract that `new CakeMix` out. Assuming it's an immutable object with no external dependencies, this shouldn't be a problem.

```
Mix mix = new CakeMix(eggs, butter, sugar);
Preparation prepareCake =
    deliciousIngredient -> mix.combinedWith(deliciousIngredient);
```

Then we can collapse that lambda expression into a method reference.

```
Mix mix = new CakeMix(eggs, butter, sugar);
Preparation prepareCake = mix::combinedWith;
```

### Well.

Yes. It's weird, but it works out.

We're assigning `prepareCake` a reference to the `combinedWith` method of `mix`:

```
mix::combinedWith
```

`mix::combinedWith` is a *method reference*. Its type looks like this:

```
Course combinedWith(Ingredient);
```

And it's (pretty much) exactly the same as `deliciousIngredient -> cakeMix.combinedWith(deliciousIngredient)`. That means it conforms to our `Preparation` interface above.

## On to the Good Stuff

### The Abstract Factory Pattern

This pattern is used *everywhere* in Java code, especially in more "enterprisey" code bases. It involves an interface and an implementation. The interface looks something like this:

```
public interface Bakery {
    Pastry bakePastry(Topping topping);
    Cake bakeCake();
}
```

And the implementation:

```
public class DanishBakery implements Bakery {
    @Override public Pastry bakePastry(Topping topping) {
        return new DanishPastry(topping);
    }

    @Override public Cake bakeCake() {
        return new Aeblekage(); // mmmm, apple cake...
    }
}
```

More generally, the Abstract Factory pattern is usually implemented according to this structure.

<div class="image">

![Abstract Factory pattern UML diagram](https://assets.noodlesandwich.com/talks/design-patterns-in-the-21st-century/abstract-factory-pattern-uml.png)

</div>

In this example, `Pastry` and `Cake` are "abstract products", and `Bakery` is an "abstract factory". Their implementations are the concrete variants.

Now, that's a fairly general example.

In actual fact, most factories only have one "create" method.

```
@FunctionalInterface
public interface Bakery {
    Pastry bakePastry(Topping topping);
}
```

Oh look, it's a function.

This denegerate case is pretty common in in the Abstract Factory pattern, as well as many others. While most of them provide for lots of discrete pieces of functionality, and so have lots of methods, we often tend to break them up into single-method types, either for flexibility or because we just don't need more than one thing at a time.

So how would we implement this pastry maker?

```
public class DanishBakery implements Bakery {
    @Override public Pastry apply(Topping topping) {
        return new DanishPastry(Topping topping);
    }
}
```

OK, sure, that was easy. It looks the same as the earlier `DanishBakery` except it can't make cake. Delicious apple cake… what's the point of that?

Well, if you remember, `Bakery` has a **Single Abstract Method**. This means it's a **Functional Interface**.

So what's the functional equivalent to this?

```
Bakery danishBakery = topping -> new DanishPastry(topping);
```

Or even:

```
Bakery danishBakery = DanishPastry::new;
```

Voila. Our `DanishBakery` class has gone.

But we can go further.

```
package java.util.function;
/**
 * Represents a function that
 * accepts one argument and produces a result.
 *
 * @since 1.8
 */
@FunctionalInterface
public interface Function<T, R> {
    /**
     * Applies this function to the given argument.
     */
    R apply(T t);

    ...
}
```

We can replace the `Bakery` with `Function<Topping, Pastry>`; they have the same types.

```
Function<Topping, Pastry> danishBakery = DanishPastry::new;
```

In this case, we might want to keep it, as it has a name relevant to our business, but often, `Factory`-like objects serve no real domain purpose except to help us decouple our code. (`UserServiceFactory`, anyone?) This is brilliant, but on these occasions, we don't need explicit classes for it—Java 8 has a bunch of interfaces built in, such as `Function`, `Supplier` and many more in the `java.util.function` package, that suit our needs fairly well.

Here's our updated UML diagram:

<div class="image">

![Updated Abstract Factory pattern UML diagram](https://assets.noodlesandwich.com/talks/design-patterns-in-the-21st-century/abstract-factory-pattern-uml-functional.png)

</div>

Aaaaaah. Much better.

### The Adapter Pattern

The Adapter pattern bridges worlds. In one world, we have an interface for a concept; in another world, we have a different interface. These two interfaces serve different purposes, but sometimes we need to transfer things across. In a well-written universe, we can use *adapters* to make objects following one protocol adhere to the other.

There are two kinds of Adapter pattern. We're not going to talk about this one:

```
interface Fire {
    <T> Burnt<T> burn(T thing);
}
```

```
interface Oven {
    Food cook(Food food);
}

class WoodFire implements Fire { ... }

class MakeshiftOven extends WoodFire implements Oven {
    @Override public Food cook(Food food) {
        Burnt<Food> noms = burn(food);
        return noms.scrapeOffBurntBits();
    }
}
```

This form, the *class Adapter pattern*, freaks me out, because `extends` gives me the heebie jeebies. *Why* is out of the scope of this essay; feel free to ask me any time and I'll gladly talk your ears (and probably your nose) off about it.

Instead, let's talk about the *object Adapter pattern*, which is generally considered far more useful and flexible in all regards.

Let's take a look at the same class, following this alternative:

```
class MakeshiftOven implements Oven {
    private final Fire fire;

    public MakeshiftOven(Fire fire) {
        this.fire = fire;
    }

    @Override public Food cook(Food food) {
        Burnt<Food> noms = fire.burn(food);
        return noms.scrapeOffBurntBits();
    }
}
```

And we'd use it like this:

```
Oven oven = new MakeshiftOven(fire);
Food bakedPie = oven.cook(pie);
```

The pattern generally follows this simple structure:

<div class="image">

![Adapter pattern UML diagram](https://assets.noodlesandwich.com/talks/design-patterns-in-the-21st-century/adapter-pattern-uml.png)

</div>

That's nice, right?

Yes. Sort of. We can do better.

We already have a reference to a `Fire`, so constructing another object just to play with it seems a bit… overkill. And that object implements `Oven`. Which has a *single abstract method*. I'm seeing a trend here.

Instead, we can make a function that does the same thing.

```
Oven oven = food -> fire.burn(food).scrapeOffBurntBits();
Food bakedPie = oven.cook(pie);
```

We could go one further and compose method references, but it actually gets worse.

```
// Do *not* do this.
Function<Food, Burnt<Food>> burn = fire::burn;
Function<Food, Food> cook = burn.andThen(Burnt::scrapeOffBurntBits);
Oven oven = cook::apply;
Food bakedPie = oven.cook(pie);
```

This is because Java can't convert between functional interfaces implicitly, so we need to give it lots of hints about what each phase of the operation is. Lambdas, on the other hand, are implicitly coercible to any functional interface with the right types, and the compiler does a pretty good job of figuring out how to do it.

Our new UML diagram will look something like this:

<div class="image">

![Updated Adapter pattern UML diagram](https://assets.noodlesandwich.com/talks/design-patterns-in-the-21st-century/adapter-pattern-uml-functional.png)

</div>

Often, though, all we really need is a method reference. For example, take the `Executor` interface.

```
package java.util.concurrent;

/**
 * An object that executes submitted {@link Runnable} tasks.
 */
public interface Executor {
    void execute(Runnable command);
}
```

It consumes `Runnable` objects, and it's a very useful interface.

Now let's say we have one of those, and a bunch of `Runnable` tasks, held in a `Stream`.

```
Executor executor = ...;
Stream<Runnable> tasks = ...;
```

How do we execute all of them on our `Executor`?

This won't work:

```
tasks.forEach(executor);
```

It turns out the `forEach` method on `Stream` *does* take a consumer, but a very specific type:

```
public interface Stream<T> {
    ...

    void forEach(Consumer<? super T> action);

    ...
}
```

A `Consumer` looks like this:

```
@FunctionalInterface
public interface Consumer<T>
{
    void accept(T t);

    ...
}
```

At first glance, that doesn't look so helpful. But note that `Consumer` is a functional interface, so we can use lambdas to specify them really easily. That means that we can do this:

```
tasks.forEach(task -> executor.execute(task));
```

Which can be simplified further to this:

```
tasks.forEach(executor::execute);
```

Java 8 has made adapters so much simpler that I hesitate to call them a pattern any more. The concept is still very important; by explicitly creating adapters, we can keep these two worlds separate except at defined boundary points. The implementations, though? They're just functions.

### The Chain of Responsibility pattern

Here's a thing you might not see a lot.

```
@Test public void hungryHungryPatrons() {
    KitchenStaff alice = new PieChef();
    KitchenStaff bob = new DollopDistributor();
    KitchenStaff carol = new CutleryAdder();
    KitchenStaff dan = new Server();

    alice.setNext(bob);
    bob.setNext(carol);
    carol.setNext(dan);

    Patron patron = new Patron();
    alice.prepare(new Pie()).forPatron(patron);

    assertThat(patron, hasPie());
}
```

It might look odd, but the idea is fairly common. For example, the Java Servlets framework uses the concept of a `FilterChain` to model a sequence of filters upon a request.

You can use `Filter` objects to do pretty much anything with a request. Here's one that tracks how many hits there have been to a site. Notice that it passes the `request` and `response` objects onto the next filter in the chain when it's done.

```
public final class HitCounterFilter implements Filter {
    // initialization and destruction methods go here

    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain)
    {
        int hits = getCounter().incCounter();
        log(“The number of hits is ” + hits);
        chain.doFilter(request, response);
    }
}
```

We might use an object in the chain to modify the input or output (in this case, the request or response):

```
public final class SwitchEncodingFilter implements Filter {
    // initialization and destruction methods go here

    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain)
    {
        request.setEncoding(“UTF-8”);
        chain.doFilter(request, response);
    }
}
```

We might even bail out of the chain early if things are going pear-shaped.

```
public final class AuthorizationFilter implements Filter {
    // initialization and destruction methods go here

    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain)
    {
        if (!user().canAccess(request)) {
            throw new AuthException(user);
        }
        chain.doFilter(request, response);
    }
}
```

Basically, once you hit an element in the chain, it has full control.

In UML, it looks a little like this:

<div class="image">

![Chain of Responsibility pattern UML diagram](https://assets.noodlesandwich.com/talks/design-patterns-in-the-21st-century/chain-of-responsibility-pattern-uml.png)

</div>

#### This is probably bad practice.

This may be a little contentious, but I'd say that most implementations of the Chain of Responsibility pattern are pretty confusing. Because the chain relies on each and every member playing its part correctly, it's very easy to simply lose things (in the case above, HTTP requests) by missing a line or two, reordering the chain without thinking through the ramifications, or mutating the `ServletRequest` in a fashion that makes later elements in the chain misbehave.

Let's dive a little further into how we can salvage something from all of this.

Remember our hungry patron?

```
@Test public void
hungryHungryPatrons() {
    KitchenStaff alice = new PieChef();
    KitchenStaff bob = new DollopDistributor();
    KitchenStaff carol = new CutleryAdder();
    KitchenStaff dan = new Server();

    alice.setNext(bob);
    bob.setNext(carol);
    carol.setNext(dan);

    Patron patron = new Patron();
    alice.prepare(new Pie()).forPatron(patron);

    assertThat(patron, hasPie());
}
```

That assertion is using [Hamcrest matchers](https://code.google.com/p/hamcrest/wiki/Tutorial#Sugar), by the way. Check them out if you're not too familiar with them. They're amazing.

#### Step 1: Stop mutating.

Not all Chain of Responsibility implementations involve mutation, but for those that do, it's best to get rid of it as soon as possible. Making your code immutable makes it much easier to refactor further without making mistakes.

There are three cases of mutation here.

1. Each member of staff has the "next" member set later, and the patrons themselves are mutated. Instead of setting the next member of staff later, we'll construct each one with the next.
2. Though you can't see it, Alice, the `PieChef`, sets a flag on the `Pie` to mark it as `cooked` for Bob, the `DollopDistributor`. Instead of changing the object, we'll have her accept an `UncookedPie` and pass a `CookedPie` to Bob. We then adapt Bob to accept a `CookedPie`. This ensures we can't get the order wrong, as `Bob` will never receive an uncooked pie.
3. And as for the patron, we'll start off with a `HungryPatron` and have them return a new instance of themselves upon feeding.

```
@Test public void
hungryHungryPatrons() {
    KitchenStaff dan = new Server();
    KitchenStaff carol = new CutleryAdder(dan);
    KitchenStaff bob = new DollopDistributor(carol);
    KitchenStaff alice = new PieChef(bob);

    Patron hungryPatron = new HungryPatron();
    Patron happyPatron = alice.prepare(new UncookedPie()).forPatron(hungryPatron);

    assertThat(happyPatron, hasPie());
}
```

This hasn't changed much, unfortunately. It's still very confusing why we giving the pie to Alice results in the patron receiving it, and we could still get things in the wrong order or ask the wrong person to do something.

#### Step 2: Make it type-safe.

Part of the problem with the ordering is that even though Alice gives the next person a `CookedPie`, we could tell her to give it to anyone, resulting in a `ClassCastException` or something equally fun. By parameterising the types, we can avoid this, ensuring that both the input and output types are correct.

```
@Test public void
hungryHungryPatrons() {
    KitchenStaff<WithCutlery<Meal>> dan = new Server();
    KitchenStaff<Meal> carol = new CutleryAdder(dan);
    KitchenStaff<CookedPie> bob = new DollopDistributor(carol);
    KitchenStaff<UncookedPie> alice = new PieChef(bob);

    Patron hungryPatron = new HungryPatron();
    Patron happyPatron = alice.prepare(new UncookedPie()).forPatron(hungryPatron);

    assertThat(happyPatron, hasPie());
}
```

Each of our constructors will change too. For example, `PieChef`'s constructor used to look like this:

```
public PieChef(KitchenStaff next) {
    this.next = next;
}
```

And now its parameter specifies the type it accepts:

```
public PieChef(KitchenStaff<CookedPie> next) {
    this.next = next;
}
```

#### Step 3: Separate behaviours.

`KitchenStaff` does two things: prepare food, but also hand over the food to the next person. Let's split that up into two different concepts. We'll construct an instance of `KitchenStaff`, then tell them who to delegate to next.

```
@Test public void
hungryHungryPatrons() {
    KitchenStaff<WithCutlery<Meal>, Serving> dan = new Server();
    KitchenStaff<Meal, Serving> carol = new CutleryAdder().then(dan);
    KitchenStaff<CookedPie, Serving> bob = new DollopDistributor().then(carol);
    KitchenStaff<UncookedPie, Serving> alice = new PieChef().then(bob);

    Patron hungryPatron = new HungryPatron();
    Patron happyPatron = alice.prepare(new UncookedPie()).forPatron(hungryPatron);

    assertThat(happyPatron, hasPie());
}
```

In this situation, `then` doesn't modify the object directly, but instead returns a new instance of `KitchenStaff` who knows to pass it on. It looks something like this:

```
private static interface KitchenStaff<I, O> {
    O prepare(I input);

    default <Next> KitchenStaff<I, Next> then(KitchenStaff<O, Next> next) {
        return input -> {
            O output = prepare(input);
            return next.prepare(output);
        };
    }
}
```

To do this, we also have to return a value rather than operating purely on side effects, ensuring that we *always* pass on the value. In situations where we may not want to continue, we can return an `Optional<T>` value, which can contain either something (`Optional.of(value)`) or nothing (`Optional.empty()`).

#### Step 4: Split the domain from the infrastructure.

Now that we have separated the chaining from the construction of the `KitchenStaff`, we can separate the two. `alice`, `bob` and friends are useful objects to know about in their own right, and it's pretty confusing to see them only as part of the chain. Let's leave the chaining until later.

```
@Test public void
hungryHungryPatrons() {
    KitchenStaff<UncookedPie, CookedPie> alice = new PieChef();
    KitchenStaff<CookedPie, Meal> bob = new DollopDistributor();
    KitchenStaff<Meal, WithCutlery<Meal>> carol = new CutleryAdder();
    KitchenStaff<WithCutlery<Meal>, Serving> dan = new Server();

    KitchenStaff<UncookedPie, Serving> staff = alice.then(bob).then(carol).then(dan);

    Patron hungryPatron = new HungryPatron();
    Patron happyPatron = staff.prepare(new UncookedPie()).forPatron(hungryPatron);

    assertThat(happyPatron, hasPie());
}
```

So now we have a composite object, `staff`, which embodies the chain of operations. This allows us to see the individuals as part of it as separate entities.

#### Step 5: Identify redundant infrastructure.

That `KitchenStaff` type looks awfully familiar at this point.

Perhaps it looks something like this:

```
@FunctionalInterface
public interface Function<T, R> {
    R apply(T t);

    ...

    default <V> Function<T, V> andThen(Function<? super R, ? extends V> after) {
        Objects.requireNonNull(after);
        return (T t) -> after.apply(apply(t));
    }

    ...
}
```

Oh, look, it's a function! And `then` is simply function composition. Our `KitchenStaff` type appears to be pretty much a subset of the `Function` type, so why not just use that instead?

```
@Test public void
hungryHungryPatrons() {
    Function<UncookedPie, CookedPie> alice = new PieChef();
    Function<CookedPie, Meal> bob = new DollopDistributor();
    Function<Meal, WithCutlery<Meal>> carol = new CutleryAdder();
    Function<WithCutlery<Meal>, Serving> dan = new Server();

    Function<UncookedPie, Serving> staff = alice.andThen(bob).andThen(carol).andThen(dan);

    Patron hungryPatron = new HungryPatron();
    Patron happyPatron = staff.apply(new UncookedPie()).forPatron(hungryPatron);

    assertThat(happyPatron, hasPie());
}
```

#### Step 6: Optionally replace classes with lambdas and method references.

Sometimes you really don't need a full class. In this case, the implementation is simple enough that we can just use method references instead.

```
@Test public void
hungryHungryPatrons() {
    Function<UncookedPie, CookedPie> alice = UncookedPie::cook;
    Function<CookedPie, Meal> bob = CookedPie::addCream;
    Function<Meal, WithCutlery<Meal>> carol = WithCutlery::new;
    Function<WithCutlery<Meal>, Serving> dan = Serving::new;

    Function<UncookedPie, Serving> staff = alice.andThen(bob).andThen(carol).andThen(dan);

    Patron hungryPatron = new HungryPatron();
    Patron happyPatron = staff.apply(new UncookedPie()).forPatron(hungryPatron);

    assertThat(happyPatron, hasPie());
}
```

This drastically cuts down on boilerplate and lets us see what's actually going on.

Our new structure is quite different—far more so than the earlier examples.

<div class="image">

![Updated Chain of Responsibility pattern UML diagram](https://assets.noodlesandwich.com/talks/design-patterns-in-the-21st-century/chain-of-responsibility-pattern-uml-functional.png)

</div>

By decoupling the business domain (in this case, pie preparation) from the infrastructure (composed functions), we're able to come up with much cleaner, terser code. Our behavioural classes (focusing around preparation) disappeared, leaving only the domain objects themselves (`UncookedPie`, for example) and the methods on them (e.g. `cook`), which is where the behaviour should probably live anyway.

## So… what's your point?

We've seen three examples of design patterns that can be drastically improved by approaching them with a functional mindset. Together, these three span the spectrum.

  * The Abstract Factory pattern is an example of a **creational** pattern, which increases flexibility during the application wiring process
  * The Adapter pattern, a **structural** pattern, is a huge aid in object composition
  * The Chain of Responsibility pattern is a good demonstration of a **behavioural** *anti-pattern* that actually makes the communication between objects *more* rigid

We took these three patterns, made them a lot smaller, removed a lot of boilerplate, and knocked out a bunch of extra classes we didn't need in the process.

In all cases, we split things apart, only defining the coupling between them in the way objects were constructed. But more than that: we made them functional. The difference between domain objects and infrastructural code became much more explicit. This allowed us to generalise, using the built-in interfaces to do most of the heavy lifting for us, allowing us to eradicate lots of infrastructural types and concentrate on our domain.

It's funny, all this talk about our business domain. It's almost as if the resulting code became a lot more object-oriented too.
