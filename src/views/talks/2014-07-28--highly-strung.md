<div class="notes">

## Introduction

</div>

<section>

### Who are you?

<blockquote class="twitter-tweet" data-conversation="none">
  <p><a href="https://twitter.com/SamirTalwar">@SamirTalwar</a> seriously you&#39;ll be fine! it&#39;s a rant. you&#39;re one of the most talented ranters I know!</p>
  &mdash; Chris Neuroth (@c089) <a href="https://twitter.com/c089/statuses/493785174606241792">July 28, 2014</a>
</blockquote>

</section>

<section>

### What is the point of this talk?

Strings are terrifying.

</section>

<section>

### Explain, fool.

I will, I promise.

But first…

</section>

<section>

### What exactly _is_ a string?

<div class="notes">

A string (or `string`, `String`, `str`, `char*`… you name it) is a sequence of bytes or characters. In most high-level programming languages, including Java and C#, a string consists of an immutable array of characters.

They tend to look something like this.

</div>

<table class="byte-array">
    <tr>
        <td>00</td>
        <td>18</td>
        <td>F</td>
        <td>o</td>
        <td>r</td>
        <td>&nbsp;</td>
        <td>e</td>
        <td>v</td>
        <td>e</td>
        <td>r</td>
        <td>&nbsp;</td>
        <td>a</td>
        <td>n</td>
        <td>d</td>
        <td>&nbsp;</td>
        <td>a</td>
        <td>&nbsp;</td>
        <td>d</td>
        <td>a</td>
        <td>y</td>
    </tr>
</table>

<div class="notes">

That's the length of the string, which itself takes up a fixed number of bytes (four in Java), and then a series of characters, which each take one or more bytes. Java uses UTF-16, in which most characters are two bytes, but some are three.

</div>

</section>

<section>

#### Strings are for humans

<div class="shakespeare">

> All the world's a stage, and all the men and women merely players. They have their exits and their entrances; And one man in his time plays many parts.

</div>

<div class="notes">

You can put quite literally anything into a string (assuming infinite memory). They can accept any valid character, and as many of them as you want. The entire works of Shakespeare will happily sit in a string in a program on your computer, and take up a grand total of six whole megabytes of memory.

</div>

</section>

<section>

#### And strings are for computers

```xml
<?xml version="1.0"?>
<catalog>
    <book id="bk101">
        <author>Shakespeare, William</author>
        <title>As You Like It</title>
        <genre>Comedy</genre>
        <price>£4.95</price>
        <publish_date>1599-02-20</publish_date>
        <isbn>978-0141012278</isbn>
        <description>William Shakespeare's exuberant comedy
        As You Like It is his playful take on the Renaissance
        tradition of pastoral romance</description>
    </book>
</catalog>
```

<div class="notes">

We often use strings to store arbitrary, human-written text, but it's even more common to store computer-generated streams of characters. There's a hell of a lot of XML and JSON out there in the world, and humans are simply not capable of typing it all. Most of the time, the majority of a string is infrastructure to help a computer, not a human, read the important bits.

</div>

</section>

<section>

### So what's the problem?

<div class="notes">

It turns out strings themselves are very useful. Having the ability to move around arbitrary amounts of data encoded in a fashion anything can understand has served software developers very well. Unfortunately, there's a few things you can do with strings which undermine everything.

The first:

</div>

<div class="fragment">

```java
a + b
```

</div>

<div class="notes">

Yup, concatenation. That beast. Now the second:

</div>

<div class="fragment">

```java
c.split(";")
```

</div>

<div class="notes">

Oh, splitting. You devil, you.

Hold your arguments for now. All will become clear.

</div>

</section>

<div class="notes">

## Complexity

</div>

<section>

### Single Responsibility

<div class="notes">

There's a piece of code everyone has written at least once. You've done it. I've done it. Your old computer science lecturer does it all the time.

It looks like this:

</div>

```java
public String serialize() {
    String output = "";
    boolean first = true;
    for (Whatnot thingamabob : values) {
        if (first) {
            first = false;
        } else {
            output += ", ";
        }
        output += String.valueOf(thingamabob);
    }
    return output;
}
```

</section>

<section>

<div class="notes">

There's some serious problems with this. And I don't mean that it's not using a `StringBuilder`. It's unreadable. It doesn't tell you what it's doing or why it's doing it.

This piece of code is really doing two things. First of all, it's converting everything into a string. Secondly, it's sticking them together with `", "` interspersed.

Let's do that as two operations.

</div>

```java
private final String SEPARATOR = ", ";

public String serialize() {
    List<String> stringValues = new ArrayList<>();
    for (Whatnot thingamabob : values) {
        stringValues.add(thingamabob);
    }

    String output = "";
    boolean first = true;
    for (String value : stringValues) {
        if (first) {
            first = false;
        } else {
            output += SEPARATOR;
        }
        output += value;
    }
    return output;
}
```

</section>

<section>

<div class="notes">

Not much better, is it? But now we can break it apart:

</div>

```java
public String serialize() {
    return join(SEPARATOR, stringify(values));
}

private List<String> stringify(Iterable<Object> values) {
    // ...
}

private String join(String separator, Iterable<String> values) {
    // ...
}
```

</section>

<section>

<div class="notes">

And then ship it out:

</div>

```java
public String serialize() {
    return Joiner.on(SEPARATOR).join(values);
}
```

<div class="notes">

This is a clear example of how separating our concerns and focusing on one thing at a time can really improve our code quality. If we were worried about the performance of creating a second list, we could easily optimise the `join` method, and every caller would benefit for free.

</div>

</section>

<section>

### Strings are complicated

<div class="notes">

Often, our data isn't quite as structured as we'd like. You know when this happens when you receive a CSV file with instructions to pull the relevant bits out. Finding those relevant bits can sometimes be harder than you think.

</div>

```java
public class Toolboxen {
    public List<Toolbox> readToolboxen(File file) {
        try (Stream<String> lines = Files.lines(file)) {
            return lines
                .map(line -> asList(line.split(",")))
                .map(fields -> new Toolbox(fields.get(0),
                                           fields.get(2),
                                           Integer.valueOf(fields.get(1))))
                .filter(toolbox -> toolbox.hasSpanner())
                .collect(toList());
        }
    }
}
```

</section>

<section>

<div class="notes">

That's way nicer than the same behaviour in Java 7, but it's still got more than a few problems. First of all, it's common for text to have commas (`,`) in it, and it's common for CSV files to have a bit of free text. So what do we do when we have a comma? We put quotes around the entire text, of course.

Suddenly this got a lot more complicated.

</div>

```java
public class Toolboxen {
    private static final char SEPARATOR = ",";
    private static final char QUOTE = "\"";

    public List<Toolbox> readToolboxen(File file) {
        try (Stream<String> lines = Files.lines(file)) {
            return lines
                .map(line -> splitLine(line))
                .map(fields -> new Toolbox(fields.get(0),
                                           fields.get(2),
                                           Integer.valueOf(fields.get(1))))
                .filter(toolbox -> toolbox.hasSpanner())
                .collect(toList());
        }
    }
```

</section>

<section class="tiny">

```java
    private static List<String> splitLine(String line) {
        List<String> fields = new ArrayList<>();
        StringBuilder currentField;
        String rest = line.trim();
        while (!rest.isEmpty()) {
            boolean quoted = rest.charAt(0) == QUOTE;
            boolean ended = false;
            for (int i = 0; i < rest.length(); i++) {
                char c = rest.charAt(i);
                if (quoted && c == QUOTE) {
                    ended = true;
                } else if (ended && c == SEPARATOR) {
                    break;
                } else if (ended) {
                    throw new IncorrectlyQuotedFieldException();
                } else {
                    currentField.append(c);
                }
            }

            if (quoted && !ended) {
                throw new IncorrectlyQuotedFieldException();
            }

            fields.add(currentField.toString());
            rest = rest.substr(i + 1).trim();
        }
        return fields;
    }
}
```

</section>

<section>

<div class="notes">

UGH.

Now, we're still missing a lot.

- You need to be able to escape the quote character, because sometimes you'll need it inside a string.
- Quoted fields can span multiple lines.
- Every row should contain the same number of comma-separated fields.

But here's the real problem. There's tight coupling between reading the file and creating our `Toolbox` objects. We can remedy that by returning a stream and letting the caller construct the object:

</div>

```java
public class CsvReader {
    public Stream<List<String>> openCsvFile(File csvFile) {
        return Files.lines(csvFile)
            .map(line -> splitLine(line));
    }
}
```

<div class="notes">

The caller is now also responsible for closing the file, but hopefully we've made that clear in the method name. Now we can move our `CsvReader` to another package, or perhaps an entirely different module, and work on it separate from the business logic.

CSV-reading, among many other things, is infrastructure-level code. It should not be intermingled with application-level concerns. Decoupling these two will make the real purpose of the application much clearer.

</div>

</section>

<section>

### Reduce your exposure

<div class="notes">

Here's a thing we do way too often:

</div>

```java
public class Toolboxen {
    public Toolbox containingTool(String toolName) {
        if (toolName.isEmpty()) {
            throw new NotAToolException("toolName is empty");
        } else if (!VALID_TOOLS.contains(toolName)) {
            throw new NotAToolException("toolName: " + toolName);
        }

        // do the thing
    }
}
```

</section>

<section>

<div class="notes">

That's a lot of boilerplate to be copied around anywhere tools are used.

Instead, what about this?

</div>

```java
public class Toolboxen {
    public Toolbox containing(Tool tool) {
        // do the thing
    }
}
```

<div class="notes">

Depending on the desired behaviour, `Tool` could be an interface, an enumeration, or just a simple class wrapping the name. But it offers us several advantages.

First off, we've moved the error-checking somewhere else, either to the thing that constructs the `Tool` or the `Tool`'s own constructor. By converting the string into a domain object as soon as possible, we've moved our error-handling to a much earlier point in the application flow, allowing us to trust the objects in our system from that point onwards.

Secondly, we've made it absolutely obvious to any caller of this code exactly what we do and do not accept. They don't have to worry about casing, language or anything else: they know they need a `Tool` object, and provided they can find one of those, they're good.

Thirdly, it's far more extensible. If at some point in the future, the colour of a tool becomes something to consider when checking whether a tool is contained by a toolbox, we don't have to change the parameter list of this method, which means callers don't have to care. Only the implementation needs to change.

</div>

</section>

<section class="slides-only">

# Any questions so far?

</section>

<div class="notes">

## Correctness

</div>

<section>

### A perennial favourite

<div class="notes">

Pop quiz: what's wrong with this code?

</div>

```java
public boolean authenticate(String username, String password) {
    String hashedPassword = hash(password, saltFor(username));

    Statement statement = connection.createStatement();
    ResultSet resultSet = statement.executeQuery(
        "SELECT COUNT(*) count FROM users" +
        " WHERE username = '" + username + "'" +
        "   AND password = '" + hashedPassword + "'");

    resultSet.next();
    return resultSet.getInt("count") == 1;
}
```

<div class="notes">

If you said that it's not using `String.format`, you get a demerit. Stay after class.

I think most of you will know this one already. It's subject to an SQL injection attack. Sure, calling it with something like `authenticate("steve", "open-sesame")` is totally fine, but what about this?

</div>

<div class="fragment">

```java
authenticate("Eve' -- ", "totally hacking into Eve's account");
```

</div>

<div class="notes">

The resulting SQL will look like this:

</div>

<div class="fragment">

```sql
SELECT COUNT(*) count FROM users WHERE username = 'Eve' -- ' AND password = 'totally hacking into Eve's account'
```

</div>

<div class="notes">

In most databases, `--` marks the start of a comment, which continues until the end of the line, totally removing the password check from the equation.

</div>

</section>

<section>

<div class="notes">

Yup. Turns out that username will get you into a lot of badly-written websites. And it's easy to test for. On the _really_ broken ones, using `'` in your username or password will crash the website.

The correct way to do things is to, of course, use parameterised SQL:

</div>

```java
public boolean authenticate(String username, String password) {
    String hashedPassword = hash(password, saltFor(username));

    Statement statement = connection.prepareStatement(
        "SELECT COUNT(*) count FROM users" +
        " WHERE username = ?" +
        "   AND password = ?");
    statement.setString(1, username);
    statement.setString(2, hashedPassword);
    ResultSet resultSet = statement.executeQuery();

    resultSet.next();
    return resultSet.getInt("count") == 1;
}
```

<div class="notes">

This way, the database will handle the user-supplied input separately from the SQL itself, which means (assuming the database driver has been written well) any SQL in the user input will be treated as text, not code.

A number of threats to security involve convincing a program to treat data as executable instructions. Most of the attacks on Microsoft and Oracle which mean you have to update Windows and Java every seventeen minutes buffer overflow attacks. Because arrays aren't really a thing in C, you can _overflow_ the array by simply writing past the end of it; there are no checks to ensure user input fits inside the array. If you are familiar with the memory layout of the application, you can write enough that you overwrite machine instructions with your own, giving you complete control of the application execution simply by providing more text than was expected.

</div>

</section>

<section>

### Too much to think about

<div class="notes">

Earlier, we pulled some data in from a CSV file. Now we're going to send out some HTML.

We won't make the same mistake we made with the SQL. No concatenation, this time. We're going to use a templating library. Our template will look something like this:

</div>

```markup
<section id="catalog">
    <#list books as book>
        <div class="book" id="${book.id}">
            <h1><span class="title">${book.title}</span>,
                by <span class="author">${book.author}</span></h1>
            <p class="description">${book.description}</p>

            <ol class="reviews">
                <#list book.reviews as review>
                    <li>${review.text} -- ${review.reviewerName}</li>
                </#list>
            </ol>
        </div>
    </#list>
</section>
```

</section>

<section>

<div class="notes">

Easy. Sorted. Cushty.

Except no. What if one of the reviews looks something like this?

</div>

> I thought this was one of Shakespeare's best plays.
> &lt;script&gt;document.location = 'http://install.malware.com/';&lt;/script&gt;

<div class="notes">

Lovely. Everyone will be redirected to an evil website, and no one will read the other marvellous reviews. Sad faces all around.

This is known as a cross-site scripting vulnerability, or "XSS", because it's often used to inject a script from another, malicious domain. It's a very common style of exploit on the web today.

</div>

</section>

<section>

<div class="notes">

We could escape the text by using the `?html` post-processor (`${review.text?html}`):

</div>

```markup
<section id="catalog">
    <#list books as book>
        <div class="book" id="${book.id?html}">
            <h1><span class="title">${book.title?html}</span>,
                by <span class="author">${book.author?html}</span></h1>
            <p class="description">${book.description?html}</p>

            <ol class="reviews">
                <#list book.reviews as review>
                    <li>${review.text?html} -- ${review.reviewerName?html}</li>
                </#list>
            </ol>
        </div>
    </#list>
</section>
```

<div class="notes">

Great. Now go do that for all your HTML. And don't forget any!

</div>

</section>

<section>

<div class="notes">

How about we write code that really does separate the instructions from the text instead?

</div>

```java
section(id("catalog"),
    many(books.map(book ->
        div(className("book"), id(book.id()),
            h1(span(className("title"), text(book.title())),
               text(", by "),
               span(className("author"), text(book.author()))),
            p(className("description"), text(book.description()))),
        ol(className("reviews"),
           many(books.reviews().map(review ->
                li(text(review.text()),
                   text(" -- "),
                   text(review.reviewerName()))))))))
```

</section>

<section>

<div class="notes">

This may look ridiculous, so allow me to explain.

For each element type, we have a method. Here, I've used static methods to keep it a little shorter, but they could just as well be instance methods.

Here's the signature of the `section` method:

</div>

```java
public static Node section(Node... children) { ... }
```

<div class="notes">

Everything is a `Node`, not a string. `Node`'s an interface that looks something like this:

</div>

```java
public interface Node {
    String toXml();
}
```

<div class="notes">

There are three implementations of `Node`: `Element`, `Attribute` and `Text`. They all know how to render themselves, and `Text` class will escape any HTML special characters as it does so. This means that as long as we get the three implementations of `toXml` correct, which we can do with a pretty high confidence level just by writing a bunch of test cases, it should be impossible to inject HTML.

I should probably add that this HTML-building library doesn't actually exist. However, if you promise me you'll use it, I will build it for you. I think it's almost as easy to read as the HTML equivalent.

</div>

</section>

<section>

#### And now, another language

<div class="notes">

In June of 2014, this tweet became very famous:

</div>

<blockquote class="twitter-tweet" lang="en">
    <p>&lt;script class=&quot;xss&quot;&gt;<wbr/>$(&#39;.xss&#39;)<wbr/>.parents()<wbr/>.eq(1)<wbr/>.find(&#39;a&#39;)<wbr/>.eq(1)<wbr/>.click();<wbr/>$(&#39;[data-action=retweet]&#39;)<wbr/>.click();<wbr/>alert(&#39;XSS in Tweetdeck&#39;)<wbr/>&lt;/script&gt;<wbr/>♥</p>
    &mdash; *andy (@derGeruhn) <a href="https://twitter.com/derGeruhn/statuses/476764918763749376">June 11, 2014</a>
</blockquote>

<div class="notes">

Take a look at the number of retweets. This one is pretty special, but not for the reasons you might think. It exploited a bug in TweetDeck to perform an XSS attack. Fortunately, it was benign: it just popped up an alert box and retweeted itself to make everyone aware of the issue; not every attack is so friendly.

</div>

</section>

<section>

<div class="notes">

That heart at the end isn't for fun, though. This attack only works when the closing script tag is followed by a multi-byte UTF-8 character; simple ASCII doesn't trigger it, but when there's emoji, that code path gets hit.

The problem?

</div>

```javascript
for (   t = e[r],
        w.innerHTML = TD.emoji.parse(t.nodeValue),
        i = document.createDocumentFragment();
    w.hasChildNodes();
) {
    i.appendChild(w.firstChild);
    ...
}
```

</section>

<section>

<div class="notes">

The relevant bit:

</div>

```javascript
w.innerHTML = TD.emoji.parse(t.nodeValue);
```

<div class="notes">

`innerHTML` is the problem here. Any time you end up setting the HTML of an element directly, just like in the template above, you have to escape it. Failure to do so often causes bugs of this seriousness (though not normally of this scale).

Sure, we can escape when necessary and hope we've covered all the bases, but there's a better way: just don't do it. Setting the `textContent` field instead, and constructing elements using the provided functions rather than concatenating HTML together, avoids problems like this.

</div>

</section>

<section>

## This is all awful. So what do I do?

<div class="notes">

Strings are the most powerful tool we have in our programming languages. Like all things powerful, they should be used responsibly.

</div>

</section>

<section>

### The Problems, in a Nutshell

<div class="notes">

Misuse of strings can lead to bad software design, such as _coupling_ infrastructure to business logic, which can make your code hard to extend, maintain, support and test. I'd argue that strings are actually an infrastructure-level concern, and that any code related to your core logic shouldn't touch them at all.

Perhaps more importantly, strings stop us from guaranteeing _correctness_. Types are scary to some people, but strong wrappers for your data are important, because they stop us from creating massive security vulnerabilities. Munging HTML or SQL together by concatenating strings is convenient, but offers nothing in the way of security. Only by dealing with data as data and code as code can we avoid this.

</div>

</section>

<section>

### The Solution

<div class="notes">

There's a solution to both of these: use your type system properly. Create classes that wrap strings, and only expose the string itself (or a transformed variation) at the infrastructure level. Only split strings when you're ingesting the data, and at no point after. Until you need to output anything, don't concatenate at all—just store the data in sensibly-named fields and do all the work at once at the end. This helps us re-use code, avoids mixing the business with the underlying technologies and enables us to use our object-oriented programming language as it was designed, by adding methods to objects as more behaviour is required.

If you have a decent separation between your business logic and your infrastructure code, any code that munges strings belongs in the infrastructure layer, along with your HTTP endpoints, message queue adapters and database connections. You don't need them until you need to communicate with a third-party system, just like your adapters.

So, in summary, wrap your strings. Wrap them as early as possible, and don't expose them until the last possible moment.

Give it a try. I think you'll be pleasantly surprised.

</div>

</section>

<section class="slides-only">

# Thank you.

</section>

<script src="https://platform.twitter.com/widgets.js" charset="utf-8" async defer></script>
