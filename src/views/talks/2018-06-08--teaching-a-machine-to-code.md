People are awful at programming.

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

### Just Fix It, Please

My least favourite error message is "missing bracket". Y'know, you missed out a closing parenthesis, or forgot to end a function with a `}`. I mean, you know there's a problem, right computer? So go fix it!

My colleague Bruno feels the same way, so he trained an [LSTM][]-based neural network to automatically fix JavaScript code.

Try it out. If you're stuck for ideas, try this:

```
const numbers = [1, 2, 3;
numbers.forEach(console.log);
```

<figure>
  <iframe src="https://toybox.prodo.ai/widget/autofix" style="width: 100%; height: 600px; border: 0;"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/widget/autofix">Prodo.AI Toybox: Autofix</a></figcaption>
</figure>

As you can see, "Autofix" just adds missing brackets where you need them. It doesn't do much more. And it's not very good—it's just a proof of concept that we _can_ solve these kinds of problems.

This is a minor problem, but it's one that bites me every day. It's cognitive overhead of the worst sort: it's important to the machine, not to me. I know what I meant and my colleagues do too. It's just the computer that can't figure it out.

Well, now it can. 🙃

[lstm]: https://en.wikipedia.org/wiki/Long_short-term_memory

### Huh, That Looks Funny…

When looking at someone else's code (or code you wrote more than 20 minutes ago), how often do you just _know_ there's a problem before you can identify what it is? I know it happens to me a lot. I get this niggling feeling at the back of my brain that says, "Something's not right. Something is wrong here. And I'm going to find out what it is."

Humans are great at pattern recognition. After we've seen enough buggy code, we start to recognise it. JavaScript `if` blocks where one of the clauses fails to return, C++ with dodgy indentation, SQL `DELETE` statements which look a little too liberal… they pop out at you.

My colleague Sergio thought the same way. Last year, he built a neural network that tried to understand "anomalous" code. Under the hood, it tokenises the code, and for each token, tries to predict the next one. If it's highly confident in its prediction and the prediction doesn't match the actual value, it flags it as potentially wrong.

Go ahead. Try something anomalous. Here's one we saw in real life you can try (in "Line" mode):

```
const numbers = [1, 2, 3];
numbers.every(number => {
  console.log(number);
});
```

<figure>
  <iframe src="https://toybox.prodo.ai/widget/token-prediction" style="width: 100%; height: 600px; border: 0;"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/widget/token-prediction">Prodo.AI Toybox: Anomaly Detection</a></figcaption>
</figure>

You might have spotted that `every` doesn't really get us very far here. The developer intended it to run through _every_ item in the array, but what it really does is return `true` if _every_ item in the array fulfils the predicate passed to it, or `false` otherwise. Because it's a clever function, it short-circuits: if any item fails the test, it returns `false` immediately.

Typically, you'd use it like this:

```
const allOdd = numbers.every(number => number % 2 === 1);
```

In our case, the predicate always returns `undefined`, which is falsy, and so it'll stop after the first element. Not what we intended.

Change `every` to `forEach` and watch the error disappear.

This approach has been borne out by other researchers in the field, especially in 2015 when Ray et al. published [_On The "Naturalness" of Buggy Code_][on the naturalness of buggy code]. The first sentence of the abstract states:

> Real software, the kind working programmers produce by the kLOC to solve real-world problems, tends to be "natural", like speech or natural language; it tends to be highly repetitive and predictable.

By contrast, bugs are all over the place.

Our model for detecting anomalies doesn't actually work as well as we'd like. We came to the conclusion that the order of tokens just isn't enough to figure out whether something is "normal" or not; we need more information. We might be able to solve some of this by making the model look forward as well as backward, but this doesn't help when we have references to code outside our file (totally normal), or even just far enough away that it can't see it.

So we started developing our next model.

[on the naturalness of buggy code]: https://arxiv.org/abs/1506.01159

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

So let's try doing this more intelligently. My colleagues Liam and Nora have been working on teaching machines to infer types. Unfortunately, while we know how to process text using _natural language processing_ (NLP) techniques, or by using _recurrent neural networks_ (RNNs) such as the LSTM structure mentioned earlier, we're not very good at graphs. In order to do this, they've had to push the boundaries of graph-based neural networks.

This project is still very much a work in progress, but because we don't try to prove anything, instead relying on probabilities, we don't necessarily even have to have valid code to get reasonable types out.

For example, try this:

```
const tomorrow = day + 1;
const weekday = day % 7;
const isSunday = weekday % 7 === 6;
const name = isSunday ? 'Sunday' : 'No idea';
```

<figure>
  <iframe src="https://toybox.prodo.ai/widget/type-inference" style="width: 100%; height: 600px; border: 0;"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/widget/type-inference">Prodo.AI Toybox: Type Inference</a></figcaption>
</figure>

Notice how it recognises that `tomorrow` and `weekday` are numbers, even though it doesn't know the type of `day`.

We're already seeing very promising results with type inference, and we're looking to spread the love across our other tooling. Perhaps we'll see anomalous code detection rebuilt on top of our graph infrastructure soon. 😃

[wat]: https://www.destroyallsoftware.com/talks/wat

### I've Seen That Before…

Not everything has to be so _complicated_, though.

Researchers have been working on _clone detection_ for decades now. This is the scientific term for what you and I call "code duplication": two pieces of code sharing a missing abstraction. Often, they perform structural analysis in the same way that static analysers do: parse the code, build a tree, and look for similarities in the tree structure.

You and I perform clone detection too, but we do it differently. We look for code that _looks_ the same.

My colleague [Chaiyong][chaiyong raghkitwetsagul], who is a PhD student focusing on clone detection, felt the same way. So he built [Vincent][], which literally takes screenshots of code, blurs them a little bit, and looks for similarities by computing the [Jaccard index][] of the images.

So, if you have any Java code with some duplication, give it a try. (If you don't have any Java files with duplication, [here's one][cachedstream.java].)

<figure>
  <iframe src="https://toybox.prodo.ai/widget/clone-detection" style="width: 100%; height: 600px; border: 0;"></iframe>
  <figcaption><a href="https://toybox.prodo.ai/widget/clone-detection">Prodo.AI Toybox: Image-Based Clone Detection</a></figcaption>
</figure>

For the absence of doubt, this one doesn't use any machine learning techniques, just straight-up algorithms.

Chaiyong and his supervisor, [Jens Krinke][], published a paper on this technique entitled [_A Picture Is Worth a Thousand Words: Code Clone Detection Based on Image Similarity_][a picture is worth a thousand words] at the International Workshop on Software Clones 2018. I'd recommend giving it a skim (or just looking at the pictures) if you want to know how it works.

[chaiyong raghkitwetsagul]: https://cragkhit.github.io/
[vincent]: https://ucl-crest.github.io/iwsc2018-vincent-web/
[jaccard index]: https://en.wikipedia.org/wiki/Jaccard_index
[cachedstream.java]: https://github.com/SamirTalwar/Streams/blob/4e9d766f395d96e15c218720fedbf3775085f5a3/src/main/java/com/noodlesandwich/streams/implementations/CachedStream.java
[jens krinke]: http://www.cs.ucl.ac.uk/staff/j.krinke/
[a picture is worth a thousand words]: http://www0.cs.ucl.ac.uk/staff/j.krinke/publications/iwsc18.pdf

## What's next?

Hopefully I've shown you a few examples of areas in which you don't have to be satisfied with your current tools. We can break them down, ask pointed questions, capture a lot of data and then rebuild them to solve real-world problems.

One area we care about a lot is complexity. Right now, there are dozens of different code complexity metrics, the most famous of which is [cyclomatic complexity][cyclomatic complexity]. It's a popular one to measure—often people will have that terrifying warning from [SpotBugs][] (the spiritual successor to FindBugs) telling them that the method in which they added one line is now over the arbitrary threshold. It's a useful notification to refactor your code, but why a hard cut-off? And what's so special about a complexity score of 10, anyway?

Really, what we're trying to do is write "good" code, whatever that means. It's probably different for you and me (which is why that SpotBugs rule is configurable). And while I'd have a hard time explaining to you what I mean by "good" code, _I know it when I see it_.

Computers are smart, and they're getting smarter. I think we can teach one what "good" means for me and for you, and why they're different. And while we're at it, we can probably teach it the difference between something that needs fixing immediately and something we can worry about later.

The same is true of structural analysis. We have lots of rules, like only allowing a maximum of 3 public methods per Java class, or 1 class per file. But why? Wouldn't it be better to figure out what "good structure" might be, and aim for that? Maybe you use the MVC pattern in your codebase. In that case, wouldn't it be better to measure the quality of the structure by how well it adheres to the established pattern, not how well it hits an arbitrary score?

Right now, our tools are like teachers of the 1800s, slapping us on the wrists with wooden sticks whenever we make a mistake. I want my computer to pair with me, guiding me, watching out for pitfalls, warning me of upcoming crocodiles, and letting me know when I'm on the right track as well as when I'm veering off.

[cyclomatic complexity]: https://en.wikipedia.org/wiki/Cyclomatic_complexity
[spotbugs]: https://spotbugs.github.io/

## But Why Should You Care?

Machine learning is definitely here to stay. Even ignoring all the hype, it's making a remarkable difference to people's lives all the time, including yours. Google's search results and Apple's FaceID save you enormous amounts of time. Just about the only industry that doesn't use artificial intelligence to make things more efficient and less mundane is, well, ours.

In some, it's causing problems. I don't want to think about what's about to happen to the American truck-driving industry. But it doesn't have to be that way. We could be using technology to improve everyone's lives, not necessarily to destroy people's livelihoods.

And you can start with your own. The very first model I showed you today is less than 100 lines of code. It was a weekend project for fun, based on [PyTorch's Character-Level RNN tutorial][pytorch: char rnn classification tutorial].

You're creatives. You didn't get into this industry to put brackets in the right place, you came here to solve problems, to fix inefficiencies, to democratise luxuries, to understand processes, to imprint metal with your touch. You came into this world to improve the lives of yourselves and others, because you're human, and that's what humans do.

So go be a human, and teach your machine to do the mechanical parts. You can start small, but you won't get anywhere until you start.

And when you're ready to change the world, [come join us][prodo.ai jobs].

[pytorch: char rnn classification tutorial]: https://pytorch.org/tutorials/intermediate/char_rnn_classification_tutorial.html
[prodo.ai jobs]: https://prodo.ai/jobs
