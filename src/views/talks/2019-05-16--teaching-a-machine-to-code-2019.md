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

For example, try the `add` function from earlier, and then try this:

```
const tomorrow = day + 1;
const weekday = day % 7;
const isSunday = weekday === 6;
const name = isSunday ? 'Sunday' : 'No idea';
```

<figure class="embed">
  <iframe src="https://toybox.prodo.ai/widget/type-inference"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/widget/type-inference">Prodo.AI Toybox: Type Inference</a></figcaption>
</figure>

Notice how it recognises that `tomorrow` and `weekday` are numbers, even though it doesn't know the type of `day`.

We're already seeing very promising results with type inference, and we're looking to spread the love across our other tooling. Perhaps we'll see anomalous code detection rebuilt on top of our graph infrastructure soon. 😃

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
  <iframe src="https://toybox.prodo.ai/widget/autofix"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/widget/autofix">Prodo.AI Toybox: Autofix</a></figcaption>
</figure>

As you can see, "Autofix" just adds missing brackets where you need them. It doesn't do much more.

This is a minor problem, but it's one that bites me every day. It's cognitive overhead of the worst sort: it's important to the machine, not to me. I know what I meant and my colleagues do too. It's just the computer that can't figure it out.

Well, now it can. 🙃

### What's next?

I've shown you a couple of examples of areas in which you don't have to be satisfied with your current tools. We can break them down, ask pointed questions, capture a lot of data and then rebuild them to solve real-world problems.

One area we care about a lot is complexity. Right now, there are dozens of different code complexity metrics, the most famous of which is [cyclomatic complexity][cyclomatic complexity]. It's a popular one to measure—often people will have that terrifying warning from [SpotBugs][] (the spiritual successor to FindBugs) telling them that the method in which they added one line is now over the arbitrary threshold. It's a useful notification to refactor your code, but why a hard cut-off? And what's so special about a complexity score of 10, anyway?

Really, what we're trying to do is write "good" code, whatever that means. It's probably different for you and me (which is why that SpotBugs rule is configurable). And while I'd have a hard time explaining to you what I mean by "good" code, _I know it when I see it_.

Computers are smart, and they're getting smarter. I think we can teach one what "good" means for me and for you, and why they're different. And while we're at it, we can probably teach it the difference between something that needs fixing immediately and something we can worry about later.

The same is true of structural analysis. We have lots of rules, like only allowing a maximum of 3 public methods per Java class, or 1 class per file. But why? Wouldn't it be better to figure out what "good structure" might be, and aim for that? Maybe you use the MVC pattern in your codebase. In that case, wouldn't it be better to measure the quality of the structure by how well it adheres to the established pattern, not how well it hits an arbitrary score?

Right now, our tools are like teachers of the 1800s, slapping us on the wrists with wooden sticks whenever we make a mistake. I want my computer to pair with me, guiding me, watching out for pitfalls, warning me of upcoming crocodiles, and letting me know when I'm on the right track as well as when I'm veering off.

[cyclomatic complexity]: https://en.wikipedia.org/wiki/Cyclomatic_complexity
[spotbugs]: https://spotbugs.github.io/

## Symbiosis

I love working with a team who aren't satisfied with the status quo. So far I've shown you how we can teach machines to be clever, or even better, _nuanced_. But sometimes we don't need them to be clever, we just need them to be machines.

### When you boil down the Agile manifesto, what do you get?

Remember _left-pad.js_?

Well, here it is again, except with more feedback. (You'll need to scroll downwards.)

<figure class="embed">
  <iframe src="https://alfie.prodo.ai/tame-stocking-filler/3"></iframe>
  <figcaption><a href="https://alfie.prodo.ai/tame-stocking-filler/3">left-pad.js in Alfie, by Prodo.AI</a></figcaption>
</figure>

[Alfie][] is a project inspired by Bret Victor's famous talk, [_Inventing on Principle_][inventing on principle], that we built for last year's [Advent of Code][] to help people get started solving algorithmic problems. If you scroll down, you'll see that I've left a bug in there for you—the same bug we mentioned earlier. Note how two out of the four "test cases" are wrong. Have a go at fixing them and see how the results change.

Alfie was just an experiment, but one that really showed us the value of immediate feedback to the developer. Why wait until you've finished typing before reporting results? And why wait until the developer sets up their debugger before showing them what's going on inside their code?

It turns out machines don't need to be smart to help you. Because machines excel at one thing: processing a lot of data very fast. Sometimes we don't need the machine to make a decision about that data—it just needs to present it to a human who can apply their intelligence to it.

If you haven't read the [Agile manifesto][] (or it's been a while), I encourage you to take another look. Because when you boil down the principles, they all really say the same thing: **give us more feedback**.

[advent of code]: https://adventofcode.com/
[agile manifesto]: https://agilemanifesto.org/
[alfie]: https://alfie.prodo.ai/
[inventing on principle]: https://vimeo.com/36579366

### Front-end development is real development

Alfie was "just" an experiment, but it was a highly successful one. So we decided to pursue it. One of the decisions we made in turning this into something more substantial was to focus on professional software developers, not people training for interviews or learning to program. While there's real value in fast, visual feedback for people in those spaces, we want to prove that developers with experience have a need for these kinds of tools too.

Enter our new project, codenamed "Snoopy". (We like dogs.)

Snoopy is Alfie, for React components. It's the equivalent of your TDD workflow, except way more visual and a lot more subjective. Because with user interfaces, there isn't a "right answer" so much as "this feels right".

Unlike the others, there's no online demo (yet). Instead, you'll need to run `npx @prodo-ai/snoopy-cli` inside a React project and configure it a little. (This'll change when we get to a proper release.)

Just like Alfie, you can change code and watch the results update as you save. But you can do it from the comfort of your own editor, on a real project. Over the coming weeks, we plan on delivering more and more information directly into your eyeballs via Snoopy. Just like Alfie, the goal is to give you feedback faster than you could ever get it before. Over time, we're planning on adding snapshot testing, diffs (so you can see what changed), GitHub pull request integration, and much more. And just like you all, we're looking for feedback, so please try it out and tell me what you think.

Snoopy doesn't contain any machine learning… yet. Because in the last few months, we've been re-evaluating our goals. We want machines to make your lives easier. This doesn't just mean writing code for you, but also helping you write better code.

Sure, you can change some code and watch your page refresh, but that's not really good enough. It doesn't show you what it looks like on a mobile screen, or how that button looks everywhere it's used. Snoopy aims to empower you by giving you all the information you need to do a good job. And we're not done until you aren't clicking buttons to get there.

## Why Should You Care?

Machine learning is definitely here to stay. Even ignoring all the hype, it's making a remarkable difference to people's lives all the time, including yours. I can search for anything I want and find it quickly on the web, and unlock my phone with my face.

Just about the only industry that doesn't use artificial intelligence to make things more efficient and less mundane is, well, ours.

And you can start with your own. The _Autofix_ model I showed you today started off as a weekend project for fun, based on [PyTorch's Character-Level RNN tutorial][pytorch: char rnn classification tutorial].

If machine learning's not your bag, that's OK. There's a thousand ways to improve our work, starting with making tools focused on the problems at hand, not whatever solution was suitable 30 or 40 years ago.

You're creatives. You didn't get into this industry to put brackets in the right place, you came here to solve problems, to fix inefficiencies, to democratise luxuries, to understand processes, to imprint metal with your touch. You came into this world to improve the lives of yourselves and others, because you're human, and that's what humans do.

So go be a human, and teach your machine to do the mechanical parts. You can start small, but you won't get anywhere until you start.

After all, <q>Nous sommes nos choix.</q>

[pytorch: char rnn classification tutorial]: https://pytorch.org/tutorials/intermediate/char_rnn_classification_tutorial.html
[prodo.ai jobs]: https://prodo.ai/jobs
