What does it mean to be human?

Foucault said:

> "Je ne pense pas qu'il soit nécessaire de savoir exactement qui je suis. Ce qui fait l'intérêt principal de la vie et du travail est qu'ils vous permettent de devenir quelqu'un de différent de ce que vous étiez au départ."
>
> "I don't feel that it is necessary to know exactly what I am. The main interest in life and work is to become someone else that you were not in the beginning."
>
> <cite>— Michel Foucault</cite>

Descartes put it more simply:

> "Cogito ergo sum."
>
> "I think, therefore I am."
>
> <cite>— René Descartes</cite>

And for the core of it all, we need look no further than Sartre.

> "Nous sommes nos choix."
>
> "We are our choices."
>
> <cite>― Jean-Paul Sartre</cite>

In short, we're nothing like machines.

<table>
  <thead>
    <tr>
      <td><strong>Humans</strong></td>
      <td><strong>Machines</strong></td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>make guesses</td>
      <td>are logical</td>
    </tr>
    <tr>
      <td>are forgiving</td>
      <td>are precise</td>
    </tr>
    <tr>
      <td>assume from context</td>
      <td>are unassuming</td>
    </tr>
    <tr>
      <td>are visual</td>
      <td>process bits</td>
    </tr>
  </tbody>
</table>


In this talk, I'm going to show you three experiments and a look into the future. I'm not going to show you how all these tie together; they will, but not yet. This is a journey for us, and I'm going to take you on that journey with me.

---

Humans are awful at programming.

Let's take a simple piece of code as an example: the infamous [_left-pad.js_][left-pad]. This library pads strings to the left, so that, for example:

```
> leftPad(37, 5, '0')
'00037'
```

Here's the implementation (with cache and comments removed for terseness):

```
module.exports = leftPad;

var cache = [ /* ... */ ];

function leftPad (str, len, ch) {
  str = str + '';
  len = len - str.length;
  if (len <= 0) return str;
  if (!ch && ch !== 0) ch = ' ';
  ch = ch + '';
  if (ch === ' ' && len < 10) return cache[len] + str;
  var pad = '';
  while (true) {
    if (len & 1) pad += ch;
    len >>= 1;
    if (len) ch += ch;
    else break;
  }
  return pad + str;
}
```

Turns out that this solution to padding strings on the left has taken 60 commits so far. It's very good, but represents a large amount of work for something that, conceptually, is pretty simple.

For example, here's commit [`6b25e77`](https://github.com/stevemao/left-pad/commit/6b25e7775731eb0f5bb5d243a84f609707da6bd7):

```diff
@@ -6,6 +6,8 @@ function leftpad (str, len, ch) {
   ch || (ch = ' ');
   len = len - str.length;

+  str = String(str);
+
   while (++i < len) {
     str = ch + str;
   }
```

This makes sure that the `str` is actually a string. Now, here's the subsequent commit, [`7aa20d4`](https://github.com/stevemao/left-pad/commit/7aa20d4289b7c706787adfcff7056f7bc0349e62):

```diff
@@ -1,12 +1,13 @@
 module.exports = leftpad;

 function leftpad (str, len, ch) {
+  str = String(str);
+
   var i = -1;

   ch || (ch = ' ');
   len = len - str.length;

-  str = String(str);

   while (++i < len) {
     str = ch + str;
```

The previous commit had a bug, where the function would access `str.length` before converting it to a string. This was obviously broken (which is why it was fixed 2 minutes later).

(Later on, this got converted to the more idiomatic `str = str + '';`.)

I hate to tell you this, but computers are much better at finding these kinds of bugs than humans are. For example, a type checker might have caught the reference to `str.length` before the conversion, and complained about the type of `str`.

Here's my problem, though. We're dealing with JavaScript, where not knowing the type of a variable isn't a barrier to execution. I tried the [Flow][] type checker on this code and it didn't help, because it's _permissive_—if it doesn't know the type, anything goes, including references to `str.length`.

This is part of the power of JavaScript: instead of forcing you to define your specification up-front like most typed languages, it allows you to experiment with code, try stuff out, perhaps write a couple of test cases. This makes it far more accessible, allows for easier prototyping and stops you having to negotiate with the compiler. As anyone who's tried advanced trickery with generics in Java can tell you, arguing with a compiler is no fun at all.

I'd love to see a middle ground: the ease of dynamic coding at the start, with the power of a machine helping me, not intruding, and gently pointing out mistakes without interfering with my workflow.

And I'd ideally like to do as little mechanical work as possible to get there.

[left-pad]: https://github.com/stevemao/left-pad
[flow]: https://flow.org/

## Ask Not What You Can Do For Your Machine

Why _are_ we doing mechanical work, anyway?

That's what we ask ourselves every day at [Prodo.AI][].

[prodo.ai]: https://prodo.ai/

### What even is this?

Pop quiz: what are the types of the parameters in this JavaScript code?

```
function add(x, y) {
  return x + y;
}
```

The correct answer is "we don't know". Here's why, courtesy of the node.js REPL:

```
> 1 + 2
3
> '1' + '2'
'12'
> 3 + '4'
'34'
> null + undefined
NaN
> null + 'x'
'nullx'
> {} + []
0
```

Those of you who've watched [Wat][], by Gary Bernhardt, will know that in JavaScript, you can use the `+` operator on basically everything and you'll get a result. It won't necessarily be a _meaningful_ result, but it won't be an error either.

This is why you see a lot of "You have NaN air miles" on your favourite airline's website.

All this means that inferring types statically in a dynamic language is horrendously painful.

But, y'know, I don't particularly care if you can _prove_ that the type is correct. I care that we know it's correct. And if the function's called `add`, we know it's adding numbers.

We know that code isn't really text. That's just how we edit it, as humans, because we're good at text. But code is a tree structure, and when you start drawing in the lines between, for example, a function call and the function declaration, it becomes a much more complicated graph structure.

Your favourite static analyser probably already takes this into account, and first parses the code into an _abstract syntax tree_ (AST). It then analyses _that_, not the text.

So let's try doing this more intelligently. My colleagues Liam and Jessica have been working on teaching machines to infer types. Unfortunately, while we know how to process text using _natural language processing_ (NLP) techniques, or by using _recurrent neural networks_ (RNNs), we're not very good at graphs. In order to do this, they've had to push the boundaries of graph-based neural networks.

This project is still very much a work in progress, but because we don't try to prove anything, instead relying on probabilities, we don't necessarily even have to have valid code to get reasonable types out.

For example, try the `add` function from earlier:

```
function add(x, y) {
  return x + y;
}
```

And now try this:

```
function concatenate(str1, str2) {
  return str1 + str2;
}
```

<figure class="embed">
  <iframe src="https://toybox.prodo.ai/typewriter/Types/?c=function+add%28x%2C+y%29+%7B%0A++return+x+%2B+y%3B%0A%7D%0A"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/typewriter/Types/?c=function+add%28x%2C+y%29+%7B%0A++return+x+%2B+y%3B%0A%7D%0A">Prodo.AI Toybox: Type Inference</a></figcaption>
</figure>

Notice how it recognises `x` and `y` are likely to be numbers, but `str1` and `str2` are probably strings.

We're already seeing very promising results with type inference, and we can't wait to take it further. By combining ML-based inference with more traditional logic-based inference, we get the best of both worlds, making assumptions when it feels right, but then making sure that everything ties together at the end.

[wat]: https://www.destroyallsoftware.com/talks/wat

### Just Fix It, Please

My least favourite error message is "missing comma", followed closely by "missing bracket" and "extra bracket". Y'know, you missed out a closing parenthesis, or forgot to end a function with a `}`, or copied an extra argument to a function call and forgot to insert the comma.

I mean, you know there's a problem, right computer? So go fix it!

My colleagues Bruno and Kai feel the same way, so they trained a recurrent neural network to automatically fix JavaScript code.

Try it out. If you're stuck for ideas, try this:

```
const numbers = [1, 2, 3;
numbers.forEach(console.log);
```

<figure class="embed">
  <iframe src="https://toybox.prodo.ai/autofix/DiffText/?c=const+numbers+%3D+%5B1%2C+2%2C+3%3B%0Anumbers.forEach%28console.log%29%3B%0A"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/autofix/DiffText/?c=const+numbers+%3D+%5B1%2C+2%2C+3%3B%0Anumbers.forEach%28console.log%29%3B%0A">Prodo.AI Toybox: Autofix</a></figcaption>
</figure>

As you can see, "Autofix" just adds missing punctuation where you need it. It doesn't do much more.

This is a minor problem, but it's one that bites me every day. It's cognitive overhead of the worst sort: it's important to the machine, not to me. I know what I meant and my colleagues do too. It's just the computer that can't figure it out. And I'm only human, after all.

Right now, our tools are like teachers of the 1800s, slapping us on the wrists with wooden sticks whenever we make a mistake. I want my computer to pair with me, guiding me, watching out for pitfalls, warning me of upcoming crocodiles, and letting me know when I'm on the right track as well as when I'm veering off.

## Symbiosis

I love working with a team who aren't satisfied with the status quo. So far I've shown you how we can teach machines to be clever, or even better, _nuanced_. But sometimes we don't need them to be clever, we just need them to do what machines do best.

### When you boil down the Agile manifesto, what do you get?

Remember _left-pad.js_?

Well, here it is again, except with more feedback. (You'll need to scroll downwards.)

<figure class="embed">
  <iframe src="https://alfie.prodo.ai/tame-stocking-filler/4"></iframe>
  <figcaption><a href="https://alfie.prodo.ai/tame-stocking-filler/4">left-pad.js in Alfie, by Prodo.AI</a></figcaption>
</figure>

[Alfie][] is a project inspired by Bret Victor's famous talk, [_Inventing on Principle_][inventing on principle], that we built for last year's [Advent of Code][] to help people get started solving algorithmic problems. If you scroll down, you'll see that I've left a bug in there for you—the same bug we mentioned earlier. Note how two out of the four "test cases" are wrong. Have a go at fixing them and see how the results change.

Alfie was just an experiment, but one that really showed us the value of immediate feedback to the developer. Why wait until you've finished typing before reporting results? And why wait until the developer sets up their debugger before showing them what's going on inside their code?

If you haven't read the [Agile manifesto][] (or it's been a while), I encourage you to take another look, especially at the [principles behind it][agile manifesto principles]. Because when you boil down the principles, they all really say the same thing: **give us more feedback**.

Humans are great at pattern recognition. Whereas a machine will need to understand the data in order to do anything useful for it, a human can spot a `null` or `NaN` among numbers very quickly.

It turns out machines don't need to be smart to help you. Because machines excel at one thing: processing a lot of data very fast. When a machine presents data to a human who can make a decision, a beautiful symbiosis emerges. The pair becomes far more valuable than each individual working independently.

[advent of code]: https://adventofcode.com/
[agile manifesto]: https://agilemanifesto.org/
[agile manifesto principles]: https://agilemanifesto.org/principles.html
[alfie]: https://alfie.prodo.ai/
[inventing on principle]: https://vimeo.com/36579366

### Front-end development is real development

Alfie was "just" an experiment, but it was a highly successful one. So we decided to pursue it. One of the decisions we made in turning this into something more substantial was to focus on professional software developers, not people training for interviews or learning to program. While there's real value in fast, visual feedback for people in those spaces, we want to prove that developers with experience have a need for these kinds of tools too.

Enter our new project, codenamed "Snoopy". (We like dogs.)

Snoopy is Alfie, for React components. It's the equivalent of your TDD workflow, except way more visual and a lot more subjective. Because with user interfaces, there isn't a "right answer" so much as "this feels right".

Just like Alfie, you can change code and watch the results update as you save. But you can do it from the comfort of your own editor, on a real project. And while you can watch your website change as you tweak it, this isn't enough information–you need to see your components in different states, with different screen sizes, in different contexts.

And unlike most conventional tools such as Storybook, Snoopy requires little to no configuration.

This is a sneak preview—we haven't officially launched yet. What I'm going to show you is just a small piece of the puzzle. You'll need to run `npx @prodo-ai/snoopy-cli` inside a React project and add a couple of annotations. (This'll change when we get to a proper release.)

Try it out, and let me know what you think!

And now you've seen the present, let me tell you a little about the future.

In the future, you won't need to change your device constantly. You'll see everything at once.

You won't have to write complex code to manage your state, both on the client and when synchronising with or updating a database. You'll just ask for what you need. You'll always have the complete history, and you'll never again tell yourself, "How on earth did this data get into this state?"

You won't have to write tests for your UI. They'll be automatically generated as you explore it, and edge cases will be found for you. And just like the interface, your test failures and diffs will be visual.

You won't have to wait weeks to find out if your work was successful. Instead, you'll share a live preview of what you're working on with a designer, a tester, or even your customer, allowing them to give you feedback instantly.

And we ask one thing in return, for you to help us accomplish this. We ask that you write high-quality code. Because, you see, analysis on "good" code is _easier_. We can train models to understand immutable code much faster than code that mutates. Code that's less coupled is not just easier for a human to understand, but for a machine too. And event-sourced data is far richer and more discoverable than a SQL database where no one understands how you got there.

You, the programmer, are important. You puzzle out what people mean. You transform vague ideas into pure logic, and in doing so, find the edge cases, the inconsistencies, and the outright failures of your business. I don't want you spending time puzzling out bugs in your infrastructure, I want you identifying bugs in the product.

## Why Should You Care?

I've now shown you some examples of areas in which you don't have to be satisfied with your current tools. We can break them down, ask pointed questions, capture a lot of data and then rebuild them to solve real-world problems.

One area we care about a lot is complexity. Right now, there are dozens of different code complexity metrics, the most famous of which is [cyclomatic complexity][cyclomatic complexity]. It's a popular one to measure—often people will have that terrifying warning from [SpotBugs][] (the spiritual successor to FindBugs) telling them that the method in which they added one line is now over the arbitrary threshold. It's a useful notification to refactor your code, but why a hard cut-off? And what's so special about a complexity score of 10, anyway?

Really, what we're trying to do is write "good" code, whatever that means. It's probably different for you and me (which is why that SpotBugs rule is configurable). And while I'd have a hard time explaining to you what I mean by "good" code, _I know it when I see it_.

Computers are smart, and they're getting smarter. I think we can teach one what "good" means for me and for you, and why they're different. And while we're at it, we can probably teach it the difference between something that needs fixing immediately and something we can worry about later.

The same is true of structural analysis. We have lots of rules, like only allowing a maximum of 3 public methods per Java class, or 1 class per file. But why? Wouldn't it be better to figure out what "good structure" might be, and aim for that? Maybe you use the MVC pattern in your codebase. In that case, wouldn't it be better to measure the quality of the structure by how well it adheres to the established pattern, not how well it hits an arbitrary score?

Machine learning is definitely here to stay. Even ignoring all the hype, it's making a remarkable difference to people's lives all the time, including yours. I can search for anything I want and find it quickly on the web, and unlock my phone with my face.

You can start simply. The _Autofix_ model I showed you today started off as a weekend project for fun, based on [PyTorch's Character-Level RNN tutorial][pytorch: char rnn classification tutorial].

If machine learning's not your bag, that's OK. There's a thousand ways to improve our work. We can make tools focused on the problems at hand, not whatever solution was suitable 30 or 40 years ago. And we can make tools that guide us, help us, and empower us, instead of punishing us for typos.

You're creatives. You didn't get into this industry to put brackets in the right place, you came here to solve problems, to fix inefficiencies, to democratise luxuries, to understand processes, to imprint metal with your touch. You came into this world to improve the lives of yourselves and others, because you're human, and that's what humans do.

So go be a human, and teach your machine to do the mechanical parts. You can start small, but you won't get anywhere until you start.

After all, <q>Nous sommes nos choix.</q>

[cyclomatic complexity]: https://en.wikipedia.org/wiki/Cyclomatic_complexity
[pytorch: char rnn classification tutorial]: https://pytorch.org/tutorials/intermediate/char_rnn_classification_tutorial.html
[spotbugs]: https://spotbugs.github.io/
