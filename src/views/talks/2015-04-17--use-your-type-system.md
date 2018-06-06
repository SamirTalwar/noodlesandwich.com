So I've got this website.

<div class="image">

![BuyMoarFlats.com](https://assets.noodlesandwich.com/talks/use-your-type-system/buy-moar-flats.png)

</div>

It’s got a lot of code.

But a little while ago, I started to think it’s not as good as I thought when we were first getting started.

So I got to work.

Here’s what I found.

## Readability

To steal a trick from [the folks at REA][the abject failure of weak typing], what's more readable?

[the abject failure of weak typing]: http://techblog.realestate.com.au/the-abject-failure-of-weak-typing/

This function, taken from my brand new website, _buymoarflats.com_:

```
public Stream<Integer> searchForProperties(
        boolean renting,
        int monthlyBudget,
        double latitude,
        double longitude,
        double distanceFromCentre) { ... }
```

Or this?

```
public Stream<PropertyId> abc(
        PurchasingType def,
        Budget ghi,
        Coordinate jkl,
        Radius mno) { ... }
```

It's hard to say; neither of them are great. To even begin, we'd need to define "readable".

> **readable**
> /ˈriːdəb(ə)l/
> _adjective_
>
> 1.  able to be read or deciphered; legible.
>     "a code which is readable by a computer"
>     <dl>
>         <dt>synonyms:</dt>
>         <dd>legible, easy to read, decipherable, easily deciphered, clear, intelligible, understandable, comprehensible, easy to understand<br/>
>             "the inscription is still perfectly readable"</dd>
>         <dt>antonyms:</dt>
>         <dd>illegible, indecipherable</dd>
>     </dl>
> 2.  easy or enjoyable to read.
>     "a marvellously readable book"
>     <dl>
>         <dt>synonyms:</dt>
>         <dd>enjoyable, entertaining, interesting, absorbing, engaging, gripping, enthralling, engrossing, compulsive, stimulating; worth reading, well written; <em>informal</em> unputdownable<br/>
>             "her novels are immensely readable"</dd>
>         <dt>antonyms:</dt>
>         <dd>boring, unreadable</dd>
>     </dl>

When dealing with code, the second point is valid—after all, who doesn't want code to be enjoyable?—but the first is paramount. It's clearer when we look at the synonyms: _legible_, _decipherable_, _clear_, _intelligible_, _understandable_, _comprehensible_… these are all characteristics of good code. But while they're good characteristics, they aren't really actionable. How do we _make_ code more readable?

### Read It Out Loud

Let's go back to our example:

<table class="vertical">
    <tr>
        <th>&nbsp;</th>
        <th>first</th>
        <th>second</th>
    </tr>
    <tr>
        <th>return type</th>
        <td><code class="language-java">Stream&lt;Integer&gt;</code></td>
        <td><code class="language-java">Stream&lt;PropertyId&gt;</code></td>
    </tr>
    <tr>
        <th>name</th>
        <td><code class="language-java">searchForProperties</code></td>
        <td><em>irrelevant</em></td>
    </tr>
    <tr>
        <th>buying or renting?</th>
        <td><code class="language-java">boolean renting</code></td>
        <td><code class="language-java">PurchasingType</code></td>
    </tr>
    <tr>
        <th>monthly budget</th>
        <td><code class="language-java">int monthlyBudget</code></td>
        <td><code class="language-java">Budget</code></td>
    </tr>
    <tr>
        <th>centre coordinates</th>
        <td><code class="language-java">double latitude, double longitude</code></td>
        <td><code class="language-java">Coordinate</code></td>
    </tr>
    <tr>
        <th>maximum distance</th>
        <td><code class="language-java">double distanceFromCentre</code></td>
        <td><code class="language-java">Radius</code></td>
    </tr>
</table>

We can see here that both have their problems. The second doesn't give us enough information: it tells us what it needs, but not why. Most of it can be inferred from the types, but there's a little left that is up to the user to figure out. The first, on the other hand, tells us what it needs but is open to abuse. What happens if I tell it my monthly budget is negative, or if the latitude is out of bounds? Can it handle a negative maximum distance from the centre point?

It's also way harder to read, not at the point of declaration, but at the point of usage. Let's see how we use the first one:

```
Stream<Integer> searchResults = searchForProperties(
        true, 500, 51.525094, -0.127305, 2);
```

Now, what on earth do all those numbers mean? And even when we've figured out, there's more to do. Is the budget in GBP or something else? What about the distance? Is that 2 miles? 2 kilometres? Furlongs? And what does it return? Integers? Are they house numbers?

Compare to the version with more restrictive types:

```
Stream<PropertyId> searchResults = searchForProperties(
        PropertyType.RENTAL,
        MonthlyBudget.of(500, GBP),
        Coordinate.of(51.525094, -0.127305),
        Radius.of(2, MILES));
```

That's _way_ more readable. But there's still something missing here. We can see it fairly easily in the last two parameters to this function. We're giving it coordinates and a radius, but really we're interested in only finding properties within a specific _area_, which happens to be a circle. This is both too restrictive—lots of property sites let you draw your own search boundaries on a map now—and not descriptive enough. If it's an area, let's take an `Area`!

```
Stream<PropertyId> searchResults = searchForProperties(
        PropertyType.RENTAL,
        MonthlyBudget.of(500, GBP),
        CircularArea.around(Coordinate.of(51.525094, -0.127305))
                    .with(Radius.of(2, MILES)));
```

This gets me thinking, though. All of these properties are facets of the thing we're looking for. Together, they make up a _search query_. We're constructing the search query _and_ executing the query in the same place. I'd like to construct a search query here, and let something else actually run the query.

```
public SearchQuery<PropertyId> searchForProperties(
        PurchasingType purchasingType,
        Budget budget,
        Area area) { ... }
```

That's way nicer. Now we only need one piece of code that executes a `SearchQuery` and brings back all the results.

```
public interface SearchQuery<T> {
    public Stream<T> fetch();

    public T fetchOne();
}
```

Turns out that the obvious place to put this behaviour is on the `SearchQuery` type itself. After all, the only thing we can do with a query is run it.

### What Does This Button Do?

When we actually execute this query, we'll get an `Stream<PropertyId>` back. In our make-believe database, IDs are integers, so why not just have an `Stream<Integer>` like in the first example?

`PropertyId` wraps an integer, like so:

```
public final class PropertyId {
    private final int value;

    public PropertyId(int value) {
        this.value = value;
    }

    public SearchQuery<Property> query(DatabaseConnection connection) { ... }

    public void renderTo(Somewhere else) { ... }

    // equals, hashCode and toString
}
```

It has two methods. The first, `query`, creates a `SearchQuery` that fetches the entire `Property` object, which is useful when querying for an exact property on our website. For example, when a flat hunter is looking at search results and clicks on one for more information, their browser will head to _https://buymoarflats.com/properties/12345_, which will take that ID and get all of the relevant information about the property. The second method renders the property ID to another object which is designed to display the information; for example, a `Hyperlink` object whose job it is to link to the property ID.

Oh, and it's got four more pieces of functionality:

- conversion from an integer (via the constructor)
- conversion to a string (the `toString` method)
- equality (`equals`, so we can check whether two property IDs are the same)
- hashing (`hashCode`, so we can use it in a hash-based collection such as `HashMap`)

So it has six pieces of behaviour. How many does `int` have?

Let's list them.

- addition
- multiplication
- subtraction
- division
- modulus
- negation
- bit manipulation operations such as `&`, `|`, `^` and `~`
- further bit manipulation functionality from [`java.lang.Integer`][java.lang.integer] (I count 9 separate methods)
- equality
- hashing
- comparison with other integers
- treatment as an unsigned integer
- treatment as a sign (the `Integer.signum` function returns a value representing negative, positive or zero)
- conversion to and from other number types (such as `double`)
- conversion to and from strings in decimal, hexadecimal, octal and binary
- all of the other methods on `java.lang.Integer`

For comparison, here's a Venn diagram of them both:

<div class="image">

![`PropertyId` overlapped with `int`](https://assets.noodlesandwich.com/talks/use-your-type-system/propertyid-venn-diagram.png)

</div>

That's a _lot_. When we see an `int` or an `Integer`, we don't know which subset of that list we're actually using. This makes them **hard to understand**; we have to infer a lot from the variable or method name in order to figure out how it will be used. We can probably assume that we're not performing bit operations on an `int id` or dividing it by 7, but you can't be sure. More seriously, we don't know if we're serializing it to a string in decimal, in hex, in base-64 or anything else. We can't tell if we're using it as an odd kind of sorting mechanism in place of listing date or something, and we have no idea if it's being accidentally converted to a floating point number elsewhere due to Java's automatic number conversion.

[java.lang.integer]: https://docs.oracle.com/javase/8/docs/api/java/lang/Integer.html

By encapsulating the integer in a `PropertyId`, we're conveying more information about what it is and what it can do. But more importantly, we're specifying what it _can't_ do, which helps us clarify its purpose. I can read the name of the type and instantly know why it's there and how it's used.

It becomes more readable.

## Searchability

It's not just humans that can read things better when they're well-typed; computers can too. Specifically, your static analysis tools, which (in the Java and C# worlds at least) catalogue everything about your software. This means that I can ask my tooling (often an IDE such as IntelliJ IDEA, Eclipse or Visual Studio) for every instance of a `PropertyId`, or every invocation of its `query` method. By contrast, searching for `int` will always be completely useless—I almost never want to find all integers in my system.

It also means I can perform automated refactoring techniques. So if I decide that `renderTo` should be called `writeTo` instead, I can ask my tools to rename it, and they can do so safely, without me having to worry about whether there is another method with the same name. Even in a dynamic language such as Python, static analysis tools have come far enough that we can perform operations like this with minimum levels of confirmation, and trust our unit tests with the rest.

There's a bigger advantage to this. We spend more time reading code than writing code. By making my code more searchable in a semi-automated fashion, I can spend less time worrying about what might need to change if I change my `PropertyId` type. I can use my time more effectively, reading the relevant code instead of trawling through irrelevant code, hoping to find the few operations that query the database by property ID instead of all the other pieces of behaviour that deal with `int`s.

## Flexibility

Remember our `searchForProperties` method? It constructs a search query. Let's expand its implementation.

```
public SearchQuery<PropertyId> searchForProperties(
        PurchasingType purchasingType, Budget budget, Area area) {
    Area rectangle = area.asRectangle();
    return connection
        .query("SELECT * FROM property"
             + " WHERE purchasing_type = ?"
             + " AND budget <= ?"
             + " AND longitude BETWEEN ? AND ?"
             + " AND latitude BETWEEN ? AND ?",
            purchasingType.name(), budget.inGBP(),
            rectangle.minX(), rectangle.maxX(),
            rectangle.minY(), rectangle.maxY())
        .filter(row -> area.contains(row.getDouble("latitude"), row.getDouble("longitude")))
        .map(row -> new PropertyId(row.getInt("id")));
}
```

That particular function searches for `PropertyId` objects using SQL against the database, then applies a couple of post-processing steps that resemble the Java 8 Streams interface.

[jooq]: http://www.jooq.org/

One of the things it makes sure to do is to extract the ID (as an integer), then convert the raw integers to objects of type `PropertyId` at the end of the operation. That's how we are, in this fictional code, returning `PropertyId` objects straight from the fetch operation.

What if we start using Cassandra instead of MySQL?

We just switch up the internals. No one has to know!

```
public final class PropertyId {
    private final UUID value;
    private final int humanRepresentation;

    public PropertyId(UUID value, int humanRepresentation) {
        this.value = value;
        this.humanRepresentation = humanRepresentation;
    }

    ...
}
```

Alright, _somebody_ has to know, but because we've kept the actual ID internal to the state, only escaping in a few constrained situations, we've massively limited the number of places in our codebase that need to change. And by keeping the integer representation, we can even keep the same URL structure.

There's clearly a win here, when dealing with strict value types, but it's also beneficial to encapsulate objects that work primarily with side effects. For example, our `SearchQuery` type. We could use jOOQ or another query builder API directly, but encapsulating it means that switching to Cassandra and using _its_ query builder only requires changing the parts of the codebase concerned with the database: namely, the queries themselves.

```
public SearchQuery<PropertyId> searchForProperties(
        PurchasingType purchasingType, Budget budget, Area area) {
    Area rectangle = area.asRectangle();
    return connection
        .query(select().from("property")
                .where(eq("purchasing_type", purchasingType.name()))
                .and(lte("budget", budget.inGBP()))
                .and(gte("longitude", rectangle.minX()))
                .and(lte("longitude", rectangle.maxX()))
                .and(gte("latitude", rectangle.minY()))
                .and(lte("latitude", rectangle.maxY())))
        .filter(row -> area.contains(row.getDouble("latitude"), row.getDouble("longitude")))
        .map(row -> new PropertyId(row.getUUID("id"), row.getInt("human_representation")));
}
```

Once this function is changed, we're done. Because we encapsulated the integer ID in the `PropertyId` class, nothing else needs to change; they still work with the `PropertyId` just as before. The `PropertyId` acts as a translation layer between the database query and the domain logic, decoupling the two and keeping each one _flexible_ with regards to the other.

## Correctness

In 2014, Corey Haines came up with a term that's been missing from the software craftsmanship dictionary: **behaviour attractor**. Often, when pulling out a new type from our codebase, we find that methods and functions that weren't really in the right place (often, private or static methods) now have a place to go, and so they naturally gravitate toward those new types during refactoring. The _behaviour_ is _attracted_ to the new type.

The simplest example of this is validation. In our first example, we had a function that ran a search query for properties. As part of this, it had to limit the search to a specific distance from a centre point. We asked ourselve earlier what would happen if the distance was somehow negative. Well, we check for it:

```
public Stream<Integer> searchForProperties(
        boolean renting,
        int monthlyBudget,
        double latitude,
        double longitude,
        double distanceFromCentre) {

    check(distanceFromCentre, is(greaterThan(0)));
    ...
}
```

Of course, there's more than one function in our system that uses distance; houses and flats are strongly tied to geography, it turns out. We've managed to knock down the validation to one line thanks to clever use of [Hamcrest matchers][hamcrest], but it's still too easy to forget that one line. We need to do better.

[hamcrest]: https://github.com/hamcrest/JavaHamcrest

Later, we changed the function signature to take a `Radius` instead of a `double`. This made the code more readable; `Radius.of(0.25, MILES)` has a lot more meaning than `0.25`. But it also provided a place for behaviour to go. The validation is one of them:

```
  public final class Radius {
      public static Radius of(@NotNull double magnitude, @NotNull DistanceUnit unit) {
          check(magnitude, is(greaterThan(0)));
          return new Radius(magnitude, unit);
      }

      private Radius(@NotNull double magnitude, @NotNull DistanceUnit unit) { ... }

      ...
  }
```

In our named constructor, we do the check. We can't forget. It's done in one place, tested once, and then left alone. Using the type system, we've made sure that the value is _always_ checked. Validation's one of those things where trusting human beings is going to lead to trouble; instead, let's trust the computer.

### Error Visibility

Another area in which we are currently trusting humans is one I've been hiding from you up to now.

```
/**
 * Searches for properties in the database matching the specified parameters.
 *
 * @param renting True if renting, false if buying.
 * ...
 * @return A stream of property IDs.
 * @throws DatabaseQueryException if there is a connection error.
 */
public Stream<Integer> searchForProperties(
        boolean renting,
        int monthlyBudget,
        double latitude,
        double longitude,
        double distanceFromCentre) { ... }
```

I don't like comments. One of the many benefits of cleaning up that function by encapsulating the parameters is that it doesn't need any of of the Javadoc any more. Everything that used to be documented in the comments is now documented in the types.

However, there's one thing that still needs Javadoc:

```
public interface SearchQuery<T> {
    /**
     * @throws DatabaseQueryException if there is a connection error.
     */
    public Stream<T> fetch();

    /**
     * @throws DatabaseQueryException if there is a connection error.
     */
    public T fetchOne();
}
```

We need to report a query failure. We could made `DatabaseQueryException` a checked exception; that should do the trick.

```
public interface SearchQuery<T> {
    public Stream<T> fetch() throws DatabaseQueryException;

    public T fetchOne() throws DatabaseQueryException;
}
```

Again, we're using the type system to convey more information to the compiler so it can help us write better code. It's no longer up to the human to decide whether the exception should be handled or not, which means it can't be forgotten. The only problem is that we now need to add `throws DatabaseQueryException` all the way up the call chain until we can handle it, which is probably done at the level of the request handler.

Now, if your code is anything like a lot of the code I've worked on, this will mean adding `throws DatabaseQueryException` **everywhere**. In my mind, this is a good thing.

_/me pauses for shock_

Surely not, right? I mean, no one likes code that looks like this:

```
@Path("/properties")
public final class PropertiesResource {
    private final Template PropertyTemplate =
        Template.inClassPath("/com/buymoarflats/website/property-details.html");

    @GET
    @Path("/{propertyId}")
    public Response propertyDetails(@PathParam("propertyId") PropertyId id) {
        try {
            return propertyResponse(id);
        } catch (DatabaseQueryException e) {
            return Response.serverError().entity(e).build();
        }
    }

    private Response propertyResponse(PropertyId id) throws DatabaseQueryException {
        Output output = formattedProperty(id);
        if (output == null) {
            return Response.notFound().entity(id).build();
        }
        return Response.ok(output).build();
    }

    private Output formattedProperty(PropertyId id) throws DatabaseQueryException {
        Property property = retrieveProperty(id);
        if (property == null) {
            return null;
        }
        return PropertyTemplate.format(property);
    }

    private Property retrieveProperty(PropertyId id) throws DatabaseQueryException {
        return id.query(connection).fetchOne();
    }
}
```

This code is pretty ugly. Every single helper method can throw a checked exception, which quickly translates into lots of visual noise. But that's not a bad thing in itself.

[Steve Freeman and Nat Pryce][growing object-oriented software] are fond of the saying, ["listen to your tests"][listening to tests]. By this, they mean that when your tests are long, ugly or hard to comprehend, they're probably telling you that you're missing something in the production code that would make things a lot better for you.

**Listen to your types.** Your code is telling you that you have not adequately decoupled your database from your business logic.

[growing object-oriented software]: http://www.growing-object-oriented-software.com/
[listening to tests]: http://pivotallabs.com/growing-software/

Let's try again.

```
@Path("/properties")
public final class PropertiesResource {
    private final Template PropertyTemplate =
        Template.inClassPath("/com/buymoarflats/website/property-details.html");

    @GET
    @Path("/{propertyId}")
    public Response propertyDetails(@PathParam("propertyId") PropertyId id) {
        try {
            return propertyResponse(id, formattedProperty(retrieveProperty(id)));
        } catch (DatabaseQueryException e) {
            return Response.serverError().entity(e).build();
        }
    }

    private Response propertyResponse(PropertyId id, Output output) {
        if (output == null) {
            return Response.notFound().entity(id).build();
        }
        return Response.ok(output).build();
    }

    private Output formattedProperty(Property property) {
        if (property == null) {
            return null;
        }
        return PropertyTemplate.format(property);
    }

    private Property retrieveProperty(PropertyId id) throws DatabaseQueryException {
        return id.query(connection).fetchOne();
    }
}
```

By rearranging the order of the calls such that the database query happens only one level down from the top, we've limited the number of methods that throw a database exception to two. We can tell, using our previous metric, that this code is better, at least in this respect; by listening to our types and letting our method signatures telling us that something was wrong, we were able to produce code which was better decoupled from the database. This means that we could extract out the formatting and response construction into a different class without any problems, as they're not touching the database call at all, increasing the flexibility but also the robustness of the code.

Code that doesn't touch the database can't fail due to a database error, after all.

#### But I don't use Java!

That's OK. Many type-safe languages have other features to take care of this. Scala has the [`Try`][scala.util.try] data type; Objective-C uses [continuation-passing style with error handlers][ios developer library: dealing with errors], and so does node.js. Haskell has [the Exception monad][control.monad.except], which can be confusing to those new to functional programming languages, but has many of the same benefits as checked exceptions and fewer of the downsides.

[scala.util.try]: http://www.scala-lang.org/api/current/#scala.util.Try
[ios developer library: dealing with errors]: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/ErrorHandling/ErrorHandling.html
[control.monad.except]: https://hackage.haskell.org/package/mtl/docs/Control-Monad-Except.html

### Optional Values

We've simplified our code by eliminating error cases, and in doing so, made chunks of it more robust. However, there's some duplication in there that is still stressing me out.

Two of our helper methods accept the possibility of `null` input, and two also return `null` in the case where there is no property by that ID. This is manageable for now, but it requires a bunch of extra test cases to ensure that the code works correctly, and means we have to be very careful about adding extra behaviour, in that we have to do more of this:

```
public Output process(Input thing) {
    if (thing == null) {
        return null;
    }
    ...
}
```

Ick.

That sort of thing is duplication of the most profane sort. So let's follow the [four rules of simple design][xp simplicity rules] and get rid of it. Let's see, hmmm… where's my Extract Method button?

Oh, wait. We can't just extract it, because it's not a complete piece of behaviour in its own right. Down one branch, it returns, but the other (implicit) branch is just the rest of the method. So really we want to extract out this construct:

```
public Output process(Input thing) {
    if (thing == null) {
        return null;
    } else {
        ...
    }
}
```

The only problem is that the `...` is a big deal. In fact, it's the point of the method, and therefore it's not going to share much with any other method which has a null check at the beginning. So what can we do about it?

Well. It doesn't share behaviour, that's for sure. But it does share structure. Its input is always our `thing`, which we now know to be non-null, and it outputs a single value. So let's borrow some thinking from the functional programming world and extract it out.

```
public Optional<Output> process(Optional<Input> thing) {
    return thing.map(value -> {
        ...
    });
}
```

Here, `thing` is not of type `Input`, but `Optional<Input>`. We can assume that the reference is non-null, as you should _never_ have a null `Optional` reference, and it has a bunch of methods designed to make it easy to use without ever asking it if there really is a value or not. `Optional`, sometimes called _Maybe_ or _Option_ in other languages, is a wrapper around the behaviour traditionally associated (in C-like languages) with `null` and null checks.

[xp simplicity rules]: http://c2.com/cgi/wiki?XpSimplicityRules

So, if `SearchQuery::fetchOne` returns an `Optional<T>` rather than a `T` which might be null, how does that affect our code?

```
@Path("/properties")
public final class PropertiesResource {
    private final Template PropertyTemplate =
        Template.inClassPath("/com/buymoarflats/website/property-details.html");

    @GET
    @Path("/{propertyId}")
    public Response propertyDetails(@PathParam("propertyId") PropertyId id) {
        try {
            return propertyResponse(id, retrieveProperty(id).map(this::formattedProperty));
        } catch (DatabaseQueryException e) {
            return Response.serverError().entity(e).build();
        }
    }

    private Response propertyResponse(PropertyId id, Optional<Output> maybeOutput) {
        return maybeOutput
            .map(output -> Response.ok(output))
            .orElse(Response.notFound().entity(id))
            .build();
    }

    private Output formattedProperty(Property property) {
        return PropertyTemplate.format(property);
    }

    private Optional<Property> retrieveProperty(PropertyId id) throws DatabaseQueryException {
        return id.query(connection).fetchOne();
    }
}
```

We can even inline all of the methods without issue, and use method references to simplify the code.

```
@Path("/properties")
public final class PropertiesResource {
    @GET
    @Path("/{propertyId}")
    public Response propertyDetails(@PathParam("propertyId") PropertyId id) {
        try {
            return id.query(connection).fetchOne()
                .map(PropertyTemplate::format)
                .map(Response::ok)
                .orElse(Response.notFound().entity(id))
                .build();
        } catch (DatabaseQueryException e) {
            return Response.serverError().entity(e).build();
        }
    }
}
```

Generics and checked exceptions are incredibly powerful tools that we can use to tell the compiler about the current state of the system. By using them to encode all possible states, including failure, we can ensure that our code _must_ handle anything that might go wrong. Instead of hiding the problem through unchecked exceptions and throwing uncontrollably whenever a `null` is encountered, we're asking the compiler to make it impossible _not_ to tackle it head-on.

## Efficiency

There are a number of benchmarks that compare correctness-enforcing types such as Java 8's new `Optional` and implementations of `Either` similar to the one above, and we won't go into them here. Suffice it to say that they do impact performance, but less than you would expect, and I would strongly suggest you don't shy away from them for that reason unless you have measurements of your own that are telling you that those are the bottlenecks.

No, the problem I want to tackle here is a little more subtle, and only occurs over time.

### Build More Features

Let's imagine that we're looking for properties, and we've created a short list:

```
Set<ShortListedProperty> shortList = connection
    .query("SELECT * FROM short_list"
         + " JOIN property"
         + " ON short_list.property_id = property.id"
         + " WHERE short_list.user_id = ?",
        user.id())
    .map(row -> propertyFrom(row))
    .fetch()
    .collect(toSet());
```

It's a set, because the order was considered unimportant at the domain level when the query was written. But of course, we'd like to show them in the same order each time—the order in which they were added to the list, with the most recent first:

```
List<ShortListedProperty> sortedShortList = shortList.stream()
    .sorted(comparing(ShortListedProperty::dateTimeAdded))
    .collect(toList());
```

Of course, at BuyMoarFlats.com, we really prize ourselves on appealing to the real estate mogul, not just the family looking to move to a new neighbourhood, so it's not uncommon for our users to shortlist properties in several cities. They'll want to just see the list in one city at a time when scheduling viewings, so we need to be able to group by city (still sorted, of course).

```
Map<City, List<ShortListedProperty>> shortListsByCity = sortedShortList.stream()
    .collect(groupingBy(ShortListedProperty::city));
```

Of course, we'll need to show the list of cities on the sidebar so it's easy to jump around:

```
Set<City> cities = shortListByCity.keySet();
```

Oh, one more thing. If properties are up for auction in the next seven days, we'll need to highlight them at the top of the screen so that the user doesn't miss them.

```
List<ShortListedProperty> upForAuctionSoon = shortListsByCity.values().stream()
    .flatMap(Collection::stream) // to flatten the lists
    .filter(property -> property.isUpForAuctionInLessThan(1, WEEK))
    .collect(toList());
```

But we don't just want to show the shortlisted auctions! Sure, those should be there, but if there's an auction and the seller is paying us for extra advertising, we need to throw it in.

```
Stream<Property> randomPromotedAuction = connection
    .query("SELECT * FROM property"
         + " WHERE sale_type = ?"
         + " AND promoted = TRUE"
         + " LIMIT 1",
        PropertySaleType.AUCTION.name())
    .fetch();

List<Property> highlighted = Stream.concat(
        randomPromotedAuction,
        upForAuctionSoon.stream())
    .collect(toList());
```

And we've got more features coming every week!

### And Build Them Well

I expect you see the problem. We have lots of different ways that we represent this data, but it's disjointed and piecemeal. This is maintenance catastrophe of the same ilk as we saw in the section on _Readability_, where we wrapped the property ID in a class to remove behaviour and provide a place for the few behaviours we needed. And we can solve it in the same way:

```
public final class ShortList {
    private final Set<ShortListedProperty> shortList;
    private final List<ShortListedProperty> sortedShortList;
    private final Map<City, List<ShortListedProperty>> shortListsByCity;
    private final Set<City> cities;
    private final List<ShortListedProperty> upForAuctionSoon;
    private final Optional<Property> randomPromotedAuction;
    private final List<Property> highlighted;

    ...
}
```

We've wrapped all of the different pieces of information that make up our short list page in one place. This is much nicer from a design perspective, as it unites what was previously a fairly haphazard set of data, but it also gives us a great opportunity to recognise the obvious efficiency problem. Previously, the functions that construct the lists, sets and maps would have been scattered; now, they'll all live in the same class, and we can easily recognise when we're doing work unnecessarily, even when we haven't worked on this area of the codebase in weeks.

We're working in Java 8 now, so each time we process a collection, the first thing we do is turn it into a `Stream<T>` using the `.stream()` method. Beforehand, we'd write a for-each loop that iterates over the collection, which constructs an `Iterator<T>` internally and ends up doing basically the same thing. This means that whether you're using loops, functional methods on your collection, [LINQ][] or anything else, you're still doing more work than you need to be.

So, we need to stop constructing new collections for each stage of the pipeline. The only three outputs here are _shortListsByCity_, _cities_ and _highlighted_; everything else is an intermediary which is no longer used outside this one class. This means that we can inline them, keeping them as streams and not bothering to `collect(toList())`. Streams, just like many collections in Scala or the output of LINQ expressions in C#, are lazy, in that they are only processed once and only when you actually evaluate them. The new code will look something like this:

```
public final class ShortList {
    public static ShortList from(DatabaseConnection conection) {
        Map<City, List<ShortListedProperty>> shortListByCity = connection
            .query("SELECT * FROM short_list"
                 + " JOIN property ON short_list.property_id = property.id"
                 + " WHERE short_list.user_id = ?"
                 + " ORDER BY short_list.date_time_added",
                 user.id())
            .map(row -> propertyFrom(row))
            .fetch()
            .collect(grouping(ShortListedProperty::city));

        Stream<ShortListedProperty> upForAuctionSoon = shortListsByCity.values().stream()
            .flatMap(Collection::stream) // to flatten the lists
            .filter(property -> property.isUpForAuctionInLessThan(1, WEEK));

        Stream<Property> randomPromotedAuction = connection ...

        List<Property> highlighted = Stream.concat(randomPromotedAuction, upForAuctionSoon)
            .collect(toList());

        return new ShortList(shortListByCity, highlighted);
    }

    ...

    public Output format() {
        ...
    }
}
```

Instead of processing the properties five times, we did it twice, purely because we got some more visibility on the situation. We even managed to offload some work onto the database. This is the power of a _behaviour attractor_, especially when refactoring legacy code that's scattered about.

[linq]: https://msdn.microsoft.com/en-us/library/bb397926.aspx

## In Conclusion

We tackled five discrete problems, but the solution has always been the same in every one of these cases. In each case, the need for a simpler design led us to create a new type. Sometimes we made types that wrapped data, in the case of `CircularArea`, `PropertyId` and `ShortList`, among others. This was to protect the data from easy access and manipulation, reducing the scope. Other times, we extracted behaviour, creating `Optional` and `Either` types to make explicit behaviour that was previously hidden by the vagaries of Java and languages like it.

In every case, our types became behaviour attractors, pulling in logic that was previously scattered (and often duplicated) everywhere. In this, we achieved [the holy grail][putting an age-old battle to rest], removing duplication _and_ increasing clarity. To keep them that way, we made sure not to expose the data in a general fashion, but only in order to fulfill the specific goals of that object.

Our code became more **readable**, **searchable**, **flexible**, **correct** and, surprisingly, more **efficient** too. While I can't promise that will happen every time, I can tell you it's worked for me far more often than not.

So what are you waiting for? Go wrap some data in some brand new types.

[putting an age-old battle to rest]: http://blog.thecodewhisperer.com/2013/12/07/putting-an-age-old-battle-to-rest/
