_Presented at a Haskell meet-up. Some knowledge of Haskell is assumed._

Nine years ago, I had a good problem.

I worked at a company in London called [TIM Group][], and we were hiring. We had a bit of a reputation at the time (and they still do) as a company that wrote high-quality software and took good care of its people, so we had quite a few applications. "Quite a few" quickly turned into "too many" and we needed a better way of filtering people. So we instituted a basic, 30-minute programming test, to be done at a time of the candidate's choosing. I can't remember what the challenge was—something about diffing dates or times—but it was something fairly easy, designed to filter out the bottom 20% or so. We allowed any programming language, any style, as long as you could write the code in half an hour.

That solved the "too many people" problem. Now we had a new problem: how to evaluate lots of random interview submissions, written in any language?

We cared about two things. Firstly, did the candidate solve the problem? We didn't need it to catch every edge case, but we expected it to at least get the basics right, and to make sure they'd identified a few of the corners.

Secondly, does it read well? Could we understand the code by reading it? Would we like to work with that code in the future? How likely is it that introducing a new feature would also introduce a brand new bug?

Now, that second one, that's probably the subject of a dozen PhD theses at this present moment, no doubt using way too many GPUs to figure out what makes code readable. (I spent a couple of years on this topic myself; [ask me sometime][@samirtalwar].) The first, though, could be automated. I mean, we knew how to write tests!

[@samirtalwar]: https://twitter.com/SamirTalwar
[tim group]: https://www.timgroup.com/

## Automate everything

So, I wrote some tests. They looked something like this:

```ruby
describe 'the difference between two dates, in days' do
  it 'should be 0 for the same date'
    result = Submission.run '2011-07-22' '2011-07-22'
    result should be 0
  end

  it 'should be 1 for dates that are one day apart'
    result = Submission.run '2012-02-19' '2012-02-20'
    result should be 1
  end

  it 'should report the correct figure for dates in the same month'
    result = Submission.run '2013-12-09' '2013-12-25'
    result should be 16
  end

  it 'should correctly calculate across months'
    result = Submission.run '2014-04-25' '2014-05-05'
    result should be 10
  end

  # You get the idea.
end
```

The Ruby aficionados among you will recognise RSpec, a DSL for tests that seems to have become quite pervasive since. (HSpec is lovely, isn't it?)

This actually worked… for Ruby code, of which we got very little, being a Java shop. So, after experimenting with JRuby for a little while and getting nowhere fast, I decided to use a universal interface for all software: `main`. By adding a `main` function to the submission, I could just pass the relevant script or binary name to the test file and let it run the program:

```ruby
module Submission
  def run(*args)
    # Run the program, return STDOUT
  end
end
```

This meant that if we could get the submission to compile/parse (and it typically didn't without a little bit of massaging), we could test it easily, regardless of language.

## In which I went a little overboard

I was excited by the idea of a test framework that didn't care which programming language you used to write your application. And it seemed fitting that such a test framework should have a language-agnostic way of defining your tests, too. And so, one night, I… [generalised][first commit]. Now you defined test cases as a pair of files: one for STDIN, and one for STDOUT. They looked like this:

_one-day.in:_

```
2012-02-19
2012-02-20
```

_one-day.out:_

```
1
```

It even supported multiple potential outputs, because… well, I cannot for the life of me remember why, but maybe dates are ambiguous sometimes?

I dubbed the project "Smoke", because the tests felt to me like [smoke tests][smoke testing]. They weren't enough to guarantee that the code was good, only that it roughly worked.

The [first version][first commit] used RSpec, but [I quickly reimplemented the tool without it][second commit]. And then… it grew.

[smoke testing]: https://en.wikipedia.org/wiki/Smoke_testing_%28software%29
[first commit]: https://github.com/SamirTalwar/smoke/commit/f0544b8ed4a593941265e63a2c0fcf0bffcf8f3f
[second commit]: https://github.com/SamirTalwar/smoke/commit/e86e35da6eb864cd88413c03e5a74a49eb6b74c4

## Time for a change

6 years, 103 commits, and 269 lines of (well-tested) Ruby code later, I realised I had a brand new problem. It was becoming hard to add functionality to Smoke, which had grown way past its original purpose, without breaking ten other features in the process. Maintaining support for Windows was tricky, because running a specific version of Ruby on Windows is a nightmare, and I kept finding odd edge cases that would take forever to debug. It was time for a change.

And so, I decided it was time to finally write Haskell in anger.

Odd choice, you might think. Smoke is a program that runs other programs and does some string comparisons. It's got "Perl" written all over it. A purely functional language hardly seems like it's going to make working with this thing either.

You'd be wrong. I was.

## A tour through the history of Smoke

I'd like to show you how things have changed over time in Smoke. Partially because I'm proud I'm still working on it after nine years, and my ego will get a kick out of it, but mostly because this was my first foray into "real" Haskell—Haskell that serves a purpose, not a proof that I am clever.[^clever]

Some will be positive experiences, some will be negative. I'd like you not to worry about whether I'm praising or insulting your favourite programming language, and instead ask yourself: how can I use this to make my life better?

Let's go.

[^clever]: _Narrator:_ The Dunning-Kruger effect is strong in this one.

### My \$10 mistake

Tony Hoare called `null` his ["billion-dollar mistake"][null references: the billion dollar mistake]. Smoke's not so widely used, but I expect it's cost me at least a tenner.

Ruby has a value called `nil`, which represents nothing. Nada. Unlike in statically-typed languages such as C or Java, this isn't so much of a problem in a dynamically-typed language, because it doesn't break the type system. If I write:

```java
Object x = new Object();
x = null;
```

You can see the type error, right? `null` isn't an `Object`. I can't call the methods of `Object` on it; if I write `null.toString()`, I get an (unchecked) exception.

On the other hand, in a dynamically-typed language, this is legit:

```ruby
x = 3
x = 'three'
x = nil
```

It's fine because `x` doesn't have a type at the time of reading, only at the time of interpretation. On line 1, its type is `Integer`. On line 2, its type is `String`. On line 3, it's `NilClass`. It's down to the reader to infer the type of the variable at any given time.

Not surprisingly, this leads to surprises. Surprises in code like the following:

```ruby
command =
  if command_override
    command_override
  elsif files[:command]
    files[:command][0].lines.collect(&:strip)
  elsif root_command
    root_command.lines.collect(&:strip)
  end
```

The above code checks whether `command_override` is `nil`; if it is, it falls back to one of two other potential cases for the command. (The _command_, in Smoke, tells it the program to run, and when this code existed, could be provided on the command line with `--smoke`, in a file named _test-case.command_, or in a file simply named _command_).

But, unfortunately, the above `command` variable can still be `nil`, because there's no `else` case. Turns out Ruby defaults to returning `nil` whenever there isn't an explicit value, and that includes missing conditional branches. Guess who forgot to account for that? Little ol' me!

You may be interested to know how long that took to fix.

Five. Years.

I don't know whether this is a testament to how buggy code can still do the job, or whether it's a scathing indictment of my programming ability. Either way, if you've ever been glad you have `Maybe` at your disposal, imagine how I feel. I can't remember how I ever programmed without it.

This code has been rewritten several times since then, but the first incarnation of the Haskell version looked something like this:

```haskell
commandForLocation <-
  return commandFromOptions <<|>>
  readCommandFileIfExists (directory </> "command")
-- ... a little later ...
command <-
  sequence (readCommandFile <$> part FileTypes.Command) <<|>>
  return commandForLocation
-- where:
(<<|>>) = liftA2 (<|>)
```

Did I forget to check whether `command` was `Nothing`? Of course not.

[null references: the billion dollar mistake]: https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/

### Just because it's built in, doesn't mean it's good

The basic type definitions in Smoke went through a somewhat tumultuous process.

Here's how a test result was defined, once I'd added some newtypes.

```haskell
data TestResult
  = TestSuccess Test
  | TestFailure TestExecutionPlan
                (PartResult Status)
                (PartResult StdOut)
                (PartResult StdErr)
  | TestError Test
              TestErrorMessage
  deriving (Eq, Show)

newtype Status = Status { unStatus :: Int }
  deriving (Eq, Show)

newtype StdIn = StdIn { unStdIn :: String }
  deriving (Eq, Show)

newtype StdOut = StdOut { unStdOut :: String }
  deriving (Eq, Show)

newtype StdErr = StdErr { unStdErr :: String }
  deriving (Eq, Show)
```

This worked; all I needed to do to check if the test passed was check the three parts (the exit status, STDOUT, and STDERR) against the expected values defined in the relevant files (_test-name.status_, _test-name.out_, and _test-name.err_).

Of course, it worked until I had some output that was a little longer than expected. Because `String` in Haskell is really `[Char]`, and when you're reading large files… that's sloooooow.

Turns out I'm not the first person to notice this. So I did some digging and converted the strings to `ByteString`. And that was a fun learning curve. The challenge wasn't changing the above code, but everything that used it. Suddenly I wasn't concatenating strings to print the results, but concatenating strings _and_ bytestrings together. I was learning new APIs, and not very well; the code I wrote was unidiomatic and overly complex, because I was unaware of the typeclasses that would have helped me trim stuff down.

But the real kicker? Bytestrings weren't appropriate either. You see, they made working with Windows really painful. (Did I mention that Smoke works on Windows? Now there's a mistake I wish I'd dodged, but it turns out supporting Windows is a good way to make sure your thing is actually useful to developers who don't get to pick their own machinery. Now if only GHC did…)

Where was I? Oh, right. Windows. Windows disagrees with Unices (Linux and macOS, as far as I'm concerned, but I'm sure there's more) on what a line looks like. You see, On a Linux machine, a new line is represented with a "line feed" character (`\n`, or `0x0a`). On Windows, it's a carriage return followed by a line feed (`\r\n` or `0x0d0a`).

This is bad. It's bad because if I write my Smoke specifications on Linux, then run the tests on Windows, they'll fail, because it'll expect Linux line endings but get Windows ones. I made it faster, but I made it worse.

The solution? Obviously, I needed to break the output into a list of lines (`[ByteString]`) and compare each line in turn.

The better solution? Use `Text`, from the `text` package. Cue another refactoring that's way too big to be a refactoring.

I had a similar issue, though for different reasons, when I changed the specification format for Smoke. As I saw the number of files in Smoke's own tests getting too unwieldy, and noticing that I couldn't really _read_ the tests and understand the behaviour any more, I decided to go with the flow and introduce some YAML. (I was working with Kubernetes at the time, and I guess Stockholm Syndrome is real.)

And so I discovered the `vector` package and `Vector a`, because that's what `aeson` (and therefore the `yaml` package) constructs when parsing a JSON array, not a list (`[a]`). While this made sense for huge JSON files, as I'm led to believe that `Vector` is way more efficient, now I had two ways of representing a list of things. Cue a confusing codebase, where there was no real reason why I'd choose one or the other apart from convenience, and a lot of conversions back and forth. (I guess I should be grateful I'd already switched to `Text`.)

I eventually switched entirely to `Vector a`, removing all lists, but I was disappointed. The standard library had let me down again. I felt like I was in the Java universe once more, with 17 choices, none of which were "right". At least with Java I had a chance of them sharing a common interface.

I worry that [Backpack][haskell backpack] is going to make this even harder. I appreciate that the experienced Haskell developer can default to a fast text implementation, but how is a newbie going to make these kind of decisions?

I want the defaults to be sensible for broad use cases. `[a]` might be beautiful in its simplicity, but it's dangerous too—we spend months learning interesting concepts that have to be thrown away when we work on anything major. Haskell's a wonderful language for building software, and I worry that already many people have thrown it away because reasoning about performance is about as easy as understanding monads in terms of a popular Tex Mex dish.

[haskell backpack]: https://gitlab.haskell.org/ghc/ghc/-/wikis/backpack

### So let's talk about burritos

The explanation of [monads as burritos][monads are like burritos] was a joke. (I think. I can never be sure with these things.) The look on people's faces when you explain that they're simply a monoid in the category of endofunctors… is not.

(Side note: I once spent six hours, with multiple people, at an unconference, trying to understand that sentence. We eventually got it. I understood it for about an hour until I went to sleep, and woke up the next morning not remembering anything. I remain unconvinced.)

So when you tell me, exceptions are just monads, I say, "Awesome, I think I know how those work. Is it like I/O?" and you say "yes", I smile.

And then I try and use the two together. And then I frown.

You see, it turns out that if you're in the `Except e` monad (which is a better-named `Either e`), you can't do I/O. and If you're in the `IO` monad… well, you can throw exceptions, but they're unchecked; you can throw any exception, even if the caller didn't expect it. And unchecked exceptions are the root of all evil. (Java got this right. It's just a shame no one wanted to listen.)

And so I started learning. I started reading about effect systems, but it seemed they weren't even close to ready yet. (I'm excited to dig into `fused-effects` after [Rob Rix's talk at ZuriHac 2020][zurihac 2020: languages all the way down], but we're talking 2017 here.)

And so I started reading more, eventually learning about monad transformers. I think the moment I tried to code with `mtl` was the stupidest I've ever felt in my entire career as a programmer, and I've put irrecoverable data in MongoDB.

Very briefly, a function making use of a monad transformer looks like this:

```haskell
executeTest :: ResolvedPath Dir -> TestPlan -> ExceptT SmokeExecutionError IO ActualOutputs
```

This looks like you're kind of nesting them. Sort of. So maybe it's like this (and remember, `Except` is basically `Either`):

```haskell
executeTest :: ResolvedPath Dir -> TestPlan -> IO (Except SmokeExecutionError ActualOutputs)
```

And, while I'm sure the above type _could_ work, good luck making sure that you can thread between working with `Except` and `IO` interchangeably. I tried. It is _really_ painful.

What `ExceptT` does is nothing short of magic. (Indistinguishable from sufficiently advanced science.) Each bind (`>>=`) operation, or each line of a `do` block, runs through _both_ monadic binds, allowing you to weave between them. Working in the outer monad (`ExceptT`) works exactly as you'd hope, and working in the inner monad (`IO`) just requires wrapping your expression in `liftIO`. If you're wrapping other monad transformers, you can even omit the lifting (or so the documentation claims), and just call the relevant functions; the types will be worked out for you in a wild, frantic mess of compiler backtracking I never want to think about.

And yet, I couldn't get my head around it. I'd only just started to understand all the various types in play before I started looking into monad transformers, and I'd finally figured out that I needed to be able to read my code at the type level, just like the compiler does. What `mtl` asked me to do was to go back to not understanding the underlying types, and instead just let the compiler do its job. It was another level, and it took me a long time to be able to just trust it to do its job.

To this day, I still have no idea how to get _in_ or _out_ of `ExceptT`. I just throw around the constructor and `runExceptT` until something compiles. I feel like I've lost something here; with a simple piece of code, I can read it and _know_ it's going to work. Monad transformers feel like programming Ruby again.

OK, not really. At least the crashes happen at compile time now.

[monads are like burritos]: https://blog.plover.com/prog/burritos.html
[zurihac 2020: languages all the way down]: https://youtu.be/kCpQ4aTzlis

### It's OK to love `IO`

When I started rewriting Smoke, I didn't know what I was doing. What I did know is that Smoke was a glorified script with a lot of test cases (but not enough). And like any script, its main job was to make something else do the work. This meant I/O, and I/O meant `IO`.

The first incarnation of the Haskell version of Smoke basically boiled down to this:

```haskell
main :: IO ()
main = do
  options <- parseOptions
  tests <- discoverTests options
  results <- runTests tests
  printResults options results
  printSummary options results
  exitAccordingTo results

parseOptions :: IO Options

discoverTests :: Options -> IO Tests

runTests :: Tests -> IO TestResults

printResults :: Options -> TestResults -> IO ()

printResult :: Options -> TestResult -> IO ()
```

We've got a chain of operations, most of which depend on the result of the previous one. We need the command line options in a few different places, but otherwise, it's a pretty simple pipeline.

Now I look at it and the types are more like this (simplified for your viewing pleasure):

```haskell
run :: ReaderT AppOptions (ExceptT SmokeError IO) ()
```

This is useful, and it works quite well. However, it's not what I needed.

We're told, as Haskell developers, that purity is sacred, and I/O should be confined to as small a surface area as possible. I think this is good advice. And like all good advice, sometimes you can toss it out of the window. There's a time for perfection, and there's a time for hacking things together, with no bounds on what you can do. (And if you can do I/O, you can do anything.)

The start of a project, even when you roughly know where you're going, is a time for the latter.

Frankly, the core of Smoke, at this point, boiled down to this (paraphrased) block of code:

```haskell
(actualExitCode, actualStdOut, actualStdErr) <-
    readProcessWithExitCode (fromJust executable) args (fromMaybe "" stdIn)
let actualStatus = convertExitCode actualExitCode
if actualStatus == expectedStatus &&
   actualStdOut `elem` expectedStdOuts &&
   actualStdErr `elem` expectedStdErrs
  then return $ TestSuccess test
  else return $ TestFailure test actualStatus actualStdOut actualStdErr
```

There's a lot more, but it's all I/O: discovery (finding the tests), printing, or handling weird error cases, such as missing command files. If you're like me, and a purist at heart, you'll strive for abstraction and reuse whenever you can. Hold off on that when you start, and for as long as you can—it's a great way to make sure you never finish. It's OK to work with `IO String` everywhere at the start, until you have a few examples of what you're trying to do, and only then start parsing or wrapping your data in more meaningful types. [As Sandi Metz says][the wrong abstraction], "duplication is far cheaper than the wrong abstraction."

I am very glad I learnt so much about YAML parsing with `aeson`, exception handling with `ExceptT`, reliable builds with `nix`, property testing with `hedgehog`, and Windows execution idiosyncrasies. (OK, not that last one. It makes me want to cry.) I'm also glad I learnt about most of them _after_ I shipped v2.0 of Smoke, because if I'd tried beforehand, this Haskell experiment would still be in the lab.

[the wrong abstraction]: https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction

### Types and scripting _can_ go together!

Smoke is no longer a script, or even a collection of scripts. It's a real program. But even when it wasn't, the type system really helped.

I had a strategy when changing code in the Ruby version: make a small change, run the tests, see what breaks. It kind of worked, but I didn't have enough tests, especially at the start. I'd make an easy-looking tweak, and everything would seem to work great, but I hadn't considered what would happen when the program under test didn't exist, or pumped out Chinese, or wrote ANSI escape sequences without a reset.

Even worse, sometimes I _did_ consider these things, but I forgot to handle them all the way through the code. I considered that the command might be missing, and would throw an exception, but forget to catch it and handle it appropriately, so Smoke would bomb.

Now, when I make an improvement, I follow an even simpler process: make a small change, compile, and see what's affected.

This works because I have newtypes _everywhere_. I don't work with `String` or `Text`, I work with `StdIn`, `StdOut`, `RelativePath Dir`, and `TestFileContents`. These declarations came pretty early on, and allowed me to make those changes from `String`, to `ByteString`, to `Text`, with minimal issues.

Early on, I realised I had a bug where Smoke would always print with color (green for a passing test, red for a failed one), even when the terminal didn't support color or ANSI escape codes. In Ruby, the challenging part wouldn't be detecting this, but threading the information through every function and object. In Haskell, I changed the appropriate code, which demanded an extra parameter… and then added the parameter everywhere else until the compiler was satisfied. It was almost entirely mechanical, and I had _proof_ the information was available, not just a hunch based on reading the code.

I've recently been bitten by my choice of `zsh` as a scripting language for a small task at work. Turns out that small task wasn't so small, and now there's a thousand lines of shell scripts. Perhaps the language was the right choice for the first week, but I regret not rewriting it in a statically-typed language such as Haskell, and I pity the poor fool[^fool] who's going to have to maintain it in six months when no one knows how it works any more.

[^fool]: _Narrator:_ The fool will be him. It's always him.

## The best tool for the job

I have absolutely no doubt that Haskell was the right choice for v2.0 of Smoke, just like Ruby was the right choice for v1.0. While Ruby brought me a general-purpose, I/O-based test framework in 40 lines of code, Haskell allowed me to build it into a fully-featured, maintainable piece of software ([which I highly recommend you use][smoke]).

I've tried to touch on a few areas why Haskell suited the needs of the project (and some areas where it didn't without some serious mental gymnastics), but the truth is, the needs of the project were somewhat irrelevant. Haskell suited _my_ needs. I didn't just need a more robust language, I also needed a challenge, some education, and something _prettier_ than the code at my day job.

I'm sure some of you work in an environment where Haskell is the best tool for the job. (And many of you will be working in an environment where [DAML][] fits the bill perfectly; I recommend checking that out.) But sometimes, the right choice is a lot more personal than that. Ask yourself and your team what would keep you around, happy to maintain something for years? Sometimes it's the money, sometimes it's the people, sometimes it's the free soda. And sometimes it's the language.

[daml]: https://daml.com/
[smoke]: https://github.com/SamirTalwar/smoke
