There's a misconception that software developers have.

We think software is important.

Because of this, we often focus the majority of our attention towards the _code_ that makes up the software. You know, the Python, or Java, or Ruby that the programmers write. We spend a lot of time grooming it, making it more maintainable, more readable, and generally _prettier_.

Unfortunately, we spend almost no time at all regarding the data that flows through our programs. Typically we're content with a few examples for our test cases, a couple of edge cases so that we can verify our systems work in some sort of staging environment… and that's about it. We tend to look at "production" data when there's a bug.

This is kind of funny, when you think about it, because the software isn't important. The data is.

Here's an example. Let's say you need to calculate your phone bill for the year. £28 per month, over 12 months.

If you're anything like me, you always know how to get hold of a calculator on your computer, phone… whatever. So you tap the numbers into your phone and you get the result: £336.

Now, what's important here? The calculator isn't important. It's just a tool that I used to get my result. The _result_ is what I care about. The result is information, which I can use to derive knowledge, and knowledge is how I get things done in life. In this case, it's how I make sure I don't starve.

## The rise of the development toolchain

Programming language tooling—compilers, interpreters and the like–are an amazing navel-gazing exercise. How insular do you have to be as a programmer to only write tools for _other programmers_? (Why yes, my company does make software development tools. Why do you ask?) So it's no surprise that all these tools focus on the _code_, because in the eyes of a software developer, code is really important. In your modern-day JavaScript development toolchain, you've got:

- a "transpiler" (which is a fancy word for "compiler")
- a dependency manager;
- a type checker;
- a test runner; and
- a bundler (which bundles all your code together in one file, because the browser doesn't believe in binaries), which:
  - imports all your dependencies,
  - removes unused code,
  - minifies the code, and
  - creates a "source map" so that your error messages are useful.

I'm probably missing something. The data toolchain, on the other hand? We've just about figured out schemas. You know, ways of making sure that some data is actually in the structure we expect. We can't really do validation very well, and we have no idea what to do about data migration, especially when the schema changes.

## In which mutation is discussed

If you're a data scientist, you're probably already aware of everything I've just written. This isn't news for you. After all, you use a Jupyter Notebook, in which code and data are equal partners in getting the job done. [Like this one][try jupyterlab]:

<p style="text-align: center;">
  <img src="/assets/presentations/plz-respect-ur-data/jupyter-notebook-lorenz.gif" alt="Jupyter Notebook - Lorenz transformation example"/>
</p>

It's got sliders! You can change the values and watch the result mutate in real time! How cool is that?

Here's your answer: NOT COOL. Because as soon as I hit Refresh, or shut down my computer, or if something goes wrong, those sliders get reset to their defaults. My data is gone. So if I value it at all, I avoid all the nifty interactive features in favour of a proper data management system (hat tip to [dotscience][] here).

Let's fix that.

## Introducing Plz

At Prodo.AI, we were faced with two problems: given a machine learning model we'd like to train, how do we ensure we don't lose the resulting model (or the input data that lead to the model), and how do we train it as cheaply as possible?

We couldn't find anything out there that didn't lock us in to their ecosystem, so… we built our own. And we called it [_Plz_][plz], because `plz run python train.py` seemed like a good joke at the time. (Still does, to be honest.)

Let me show you how it works.

1. Clone [Predestination][], my implementations of [Conway's Game of Life][].
2. Make sure it runs OK by running the following:

   ```
   make environment
   source .envrc
   ./cli
   ```

   The above runs it with the default implementation, "translate". You can press `q` to quit.

3. Now we're going to train the neural network implementation. Set up [Plz][] according to the documentation. You'll need a running controller to proceed, either locally or on the cloud somewhere.
4. Make a file named _parameters.json_ with the following contents:
   ```json
   {
     "iterations": 10000
   }
   ```
5. Run `plz run --parameters=parameters.json` inside the _predestination_ directory.
6. Watch it build a model, and note down the execution ID.
7. See what happens when you run Conway's Game of Life with a trained neural network:
   ```
   ./cli neural-network --weights-file=output/<execution-ID>/weights.pickle
   ```
8. Change the parameters (in _parameters.json_) and try it again.

The output will look something like this:

```
👌 Capturing the files in .../predestination
👌 Building the program snapshot
Step 1/4 : FROM samirtalwar/predestination
 ---> 35759770e80b
Step 2/4 : WORKDIR /src
 ---> Using cache
 ---> 58b900207243
Step 3/4 : COPY . ./
 ---> Using cache
 ---> 3f7584300ab4
Step 4/4 : CMD None
 ---> Using cache
 ---> 7c7c5c7e49bc
Successfully built 7c7c5c7e49bc
Successfully tagged plz/builds:samir-plz-1542829120973
👌 Sending request to start execution
👌 Execution ID is: 0d8d13b4-edc5-11e8-ad39-517d46984ad7
👌 Streaming logs...
Training...
Training error after 1000 iterations: 0.070134
Training error after 2000 iterations: 0.022157
Training error after 3000 iterations: 0.014752
Training error after 4000 iterations: 0.011562
Training error after 5000 iterations: 0.009714
Training error after 6000 iterations: 0.008483
Training error after 7000 iterations: 0.007593
Training error after 8000 iterations: 0.006913
Training error after 9000 iterations: 0.006375
Training error after 10000 iterations: 0.005935
Test error: 0.006924
Saved.

👌 Harvesting the output...
👌 Retrieving summary of measures (if present)...
👌 Execution succeeded.
👌 Retrieving the output...
weights.pickle
👌 Done and dusted.
```

Each time, you get a different and unique "execution ID". As long as you remember that (or, let's be honest, write it down; humans aren't great at memorising UUIDs), you can always inspect the input and output data, and re-run the program.

Try it, by running `plz describe <execution-ID>`. (If you're talking about the last execution you ran, you can omit the ID.) You'll get a bunch of information out, but notice that the parameters were captured. The output is already in _output/&lt;execution-ID&gt;_, but you can also re-download it with `plz output <execution-ID>` too. And finally, `plz rerun <execution-ID>` will re-run it (and you can provide different parameters if you like). Of course, the output is saved, so the need to re-run programs with the exact same input is reduced massively.

It's common to deal with files, rather than simple numbers when feeding input into any kind of data science. Plz will happily upload files to the controller and make them available to the job.

Oh, and one more thing.

## Hardware, the bane of our existence

At some point, training models becomes _slow_ on my 3-year old laptop. Funny, that.

Fortunately, I don't need to go and buy a big machine with a big GPU. Amazon have those, and I can use them.

Here's another example, this time in the Plz repository, under _examples/pytorch_. Start an AWS-compatible controller, then run:

```
cd examples/pytorch
plz -c plz.cuda.config.json run -p parameters.json
```

Here's my truncated output:

```
[...]
👌 Sending request to start execution
Instance status: querying availability
Instance status: requesting new instance
Instance status: waiting for the instance to be ready
Instance status: pending
Instance status: pending
Instance status: pending
Instance status: DNS name is: ec2-54-194-209-21.eu-west-1.compute.amazonaws.com
Instance status: starting container
Instance status: running
👌 Execution ID is: a018e0d0-ee46-11e8-9c27-b15bc3e3f713
👌 Streaming logs...
Using device: cuda
Epoch: 1. Training loss: 2.146244
Evaluation accuracy: 47.80 (max 0.00)
Best model found at epoch 1, with accurary 47.80
[...]
Epoch: 30. Training loss: 0.008634
Evaluation accuracy: 97.40 (max 98.00)

👌 Harvesting the output...
👌 Retrieving summary of measures (if present)...
{
  "max_accuracy": 98.0,
  "training_loss_at_max": 0.016884028911590576,
  "epoch_at_max": 29,
  "training_time": 45.41165781021118
}
👌 Execution succeeded.
👌 Retrieving the output...
le_net.pth
👌 Done and dusted.
```

Watch as it spawns as _p2.xlarge_ instance, complete with a beefy graphics card, and runs our model. It'll keep that instance around for a little while, then shut it down if it's not used.

## What's your point?

Plz operates on a set of principles:

1. The faster you can iterate, the better your results.
2. You don't know the value of your data at the time of creation.
3. Data that isn't reproducible is worthless.
4. Code is a means to an end.
5. Hardware is expensive.

When training a neural network, we care very little about the code to train the network, except that we can refine it, along with its parameters and training data, to train a better one in the future. We care about the model. Plz's job is to make sure you have that model, that you can refine it in the future, and that when you realise that the model from 20 iterations ago is your best chance at something valuable, you can work on it. And when you're not training models, Plz will shut down your EC2 instances so that you're not stuck with a huge bill.

## Data is King

Whatever field or industry you're in, none of your contemporaries or customers care about your software. It's a means to an end. They care about the end—the result, the data, the report, the conclusion.

You probably already knew this. Your tooling is behind.

Let's fix that. [Plz][] and [dotscience][] are just two examples. And they're nowhere near finished.

On the roadmap for Plz:

- parallel runs with hyper-parameter searching, so you can try 100 different iterations all at once
- cloud storage support (with AWS S3 to start), so you never lose inputs or outputs
- cloud-agnostic redesign, so you can run your code wherever you please
- a friendly UI so you can analyse your results

And that's just the stuff we're working on _now_. It's open-source. [Come and help us figure out what to do next.][plz issues]

[conway's game of life]: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
[dotscience]: https://dotscience.com/
[plz]: https://github.com/prodo-ai/plz
[plz issues]: https://github.com/prodo-ai/plz/issues
[predestination]: https://github.com/SamirTalwar/predestination
[try jupyterlab]: https://mybinder.org/v2/gh/jupyterlab/jupyterlab-demo/master?urlpath=lab%2Ftree%2Fdemo%2FLorenz.ipynb
