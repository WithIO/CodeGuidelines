# Bugs

As software developers we write features but we also write bugs. And we don't
like bugs. Actually, one of the main goal of these guidelines is to help
everyone create as few bugs as possible.

```{image} /_static/first-bug.webp
:alt: Image of the first bug
:width: 60%
:align: center
```

This document is for when you managed to create a beautiful bug and you need to
get rid of it.

```{note}
This was initially an article published on
[dev.to](https://dev.to/xowap/20-years-later-mdash-how-i-find-and-fix-bugs-5567).
This will explain the slight change of tone between this page and the others.
```

```{warning}
If a bug can only be reproduced on one computer it most likely means that out
of the dozen of people that tested out your app, one of them had the bug. That's
10% of people with that bug. It's pretty serious. Don't discard a bug because
it's weird.
```

As life might have taught you, there is no silver bullet. Some techniques are
good for some situations while some are for others. Not every problem is a nail
so you'll need more tools than a hammer. Here we go over _my_ favorite tools
when it comes to bug hunting, from crystal clear situations to the most
_quantum_ bugs.

## The obvious

When talking about debugging, a few classic tricks come to mind. They are the
most obvious and while I use them a lot it's important that they don't occupy
too much of your mind space. You know what they do, I'm going to explain when to
use them &mdash; or not.

### `print` things

Every developer will &mdash; sooner than later &mdash; use `print`,
`console.log` or their friends to debug their code. You're probably going to
expect me to say it's wrong but in truth it's really a worthy tool as long as
you use it appropriately.

By example Python comes from the
[`logging`](https://docs.python.org/3/library/logging.html) standard module. I
know it's scary as shit and makes you feel like you're doing some Java, once you
slap on some goodies like
[`coloredlogs`](https://coloredlogs.readthedocs.io/en/latest/index.html) you're
going to feel that it's not that bad. Here is a few reasons to choose a logging
module over just writing to std{out,err}.

-   They are made to print data structures and might be helpful in the
    conversion from memory to string
-   They are often widespread so other tools can integrate with them. By example
    [Sentry](https://sentry.io/welcome/) will report logs previous to an
    incident
-   They can automatically come with dates, PID numbers, thread IDs or any kind
    of contextual information that will help you understand what you're reading
-   You can adjust their level depending on if you're just running the app or if
    you're explicitly trying to debug it

**When to use it** &mdash; When you've got a complex system and most notably
when it's doing some important API calls, data modification, etc. Always good to
keep a trace of what is happening. Don't hesitate to preemptively install logs
in your app when you still remember what is important to log, which might help
you later on to understand a problem. It's also useful to check the order of
execution of functions when the sequencing matters.

**When to misuse it** &mdash; Printing stuff is commonly used to check the value
of variables inside a function or to understand what is going on during the
execution of some code. This is often counter-productive as much better tools
exist for these tasks. Introducing...

### Debuggers

Debuggers are the most obvious tools for debugging, as the name suggests. I've
seen countless juniors and less juniors being afraid of using debuggers. For
sure, it's probably intimidating beasts at first glance but their usefulness
will make you forget the pain.

The first blocking point to debuggers is often the setup. I know that the
Python, Java or even the PHP process is nice with things out of the
[IDEA family](https://www.jetbrains.com/products/#type=ide). In the JS world
you'll have various luck depending on your build chain and how much of code maps
worked (so probably not much).

Once the tool is setup and that you have established some trust in the
breakpoints, it's time to start using it. Mainly you can:

-   Explore data structures at a given point in time, with the program
    completely on pause. Especially useful when using a dynamically-typed
    language and you're not sure what exactly the data is going to be.
-   Try-and-test expressions quickly and _in situ_. Very useful for fine-tuning
    `if` conditions by example.
-   See what happens step-by-step to finally understand what goes wrong in your
    code.

**When to use it** &mdash; You've identified more or less where the code goes
wrong &mdash; by example from the stack trace &mdash; but you still need to
understand why. Or maybe you're writing some code but you need to know what are
your options: what is the precise type of parameters, what properties do they
have, etc. Once I've used a debugger simply to understand the behavior of Apache
on some precise matters! Debuggers are for precision work.

**When to misuse it** &mdash; Something somewhere is broken but you have no clue
what. Something is broken _sometimes_ but you don't know under which conditions.

### App-level monitoring

When "on your machine it works" but that production disagrees with you, you'll
need to know what exactly happened. And you'll need to know that it happened at
all. As mentioned earlier, I personally am very satisfied with
[Sentry](https://sentry.io/welcome/), however other options might be suitable.

-   Get notified as soon as something unusual happens in your code, whether it's
    an exception or some custom message sent by your code
-   See the decoded stack trace with relevant parts of the source code
-   At each level of the stack, see the value of variables
-   Inspect the logs surrounding the event

**When to use it** &mdash; To detect and understand any bug happening in
production. At least, to gather the data that will help you reproduce the said
bug and then move to another technique.

**When to misuse it** &mdash; I've not seen any serious misuse of it. Just make
sure to disable Sentry when using the app on your dev machine.

## The blind

While some bugs are obviously easy to trigger and to locate, others can be very
tricky to understand. Maybe they are related to a specific browser version,
maybe a specific screen density will cause problems or maybe an undefined
sequence of actions will get you into trouble. In those cases, you have
potentially no idea of what is going on yet something that worked before is
broken now or maybe just a share of your users have an issue.

In those cases you'll often feel like it's not really a bug. That the user is
doing something wrong. That they should empty their cache or use a different
computer and it will solve the problem. But one thing is for sure: the user is
never wrong. At least, your application must not crash due to the user's
behavior. And it's not because the bug is elusive that it is less real.

Those special cases are in fact the hardest to debug. We will try here to cover
the basic ideas which can let you efficiently unlock the situation.

### Bisecting

So you've developed some feature and you know for a fact that it used to work
quite well. Maybe you convince yourself by checking the database and seeing that
it has indeed been widely used. Yet, now it's broken and you don't know why.
Obviously the code that pertains directly to this feature didn't change but
something between there and here broke it, the only question being to find out
which one of those 200 commits is responsible.

That's where
[bisection](<https://en.wikipedia.org/wiki/Bisection_(software_engineering)>)
comes into play and more specifically
[`git bisect`](https://git-scm.com/docs/git-bisect). In a nutshell, you tell it
the most recent commit you known where it worked, the earliest commit you know
where it was broken and then it will help you find the exact commit at which the
problem happened.

Typically helpful to figure when one of your colleagues introduced this CSS rule
in another file which is completely affecting your component.

**When to use it** &mdash; Something worked before and doesn't work anymore but
you don't know why. Usually finding the faulty commit will quickly lead to a "oh
fuck" moment.

**When to misuse it** &mdash; If you're not sure that it ever worked properly or
that the trigger conditions are weird then don't lose your time with this.

### Slashing

There is a few contexts where not loading the code will not prevent the app from
displaying to some extent. By example if your JS code doesn't load then it's
just that some buttons won't work. On the other hand, a syntax error anywhere
could cause the whole thing to fail.

When something somewhere in my JS code is preventing the rest from loading, my
usual plan would be to comment out all the code except the one that I want to
work. Then I check if it works. If it does, I un-comment half of the commented
code and vice-versa otherwise. I do this until I find the fault piece of code.

This also applies to server-side logic. I can end up isolating pieces of code by
commenting most of the code around it, forcing some conditions, mocking the API
responses, etc. This can also be done with unit tests. What matters here is to
isolate the precise location of the bug.

Those are just examples, writing a generic guide on this practice would take
more than a few paragraphs. The core thinking behind this is to disable
everything that could cause harm and that is not necessary to test your feature,
then to progressively enable the rest. When you find the precise thing that once
enabled breaks your code then you know what to fix.

**When to use it** &mdash; You don't know what but something prevents your code
from executing properly.

**When to misuse it** &mdash; That's definitely not a go-to option in many
cases. Try to think the problem through and read your code before commenting
half your project out.

### Random testing

One of the hardest bug I've ever had to find had a report alike to this:

> Sometimes when I'm on page X and I click on that button then the app crashes

After inspecting the code of the button through and through it felt like I had
no idea what could even go wrong, I figured that the bug was probably the side
effect of some middleware, hook or other transversal piece of code. Even armed
with this idea though, I could not find what.

So I wrote a custom "unit test". The idea was the following: I scripted a
Selenium driver to randomly click on the website and do random actions until
those actions lead the "user" to the buggy page. Then it would automatically
perform the buggy action and see if the bug was present or not.

After running a few hundreds of those tests and looking at the logs it became
obvious that it was the prior navigation to a specific page that triggered the
bug. Some code was missing to reset global states. This code had to be present
on all the pages but was forgotten from this particular one. I guess the morale
of this story is that no breakpoint can ever stop into the code that is missing.

**When to use it** &mdash; This is a last-resort option for when your bug report
is "sometimes when I do I'm not too sure what then it crashes". I've had to use
it _once_ ever.

**When to misuse it** &mdash; It's so hard to setup that you will hardly think
about it if you don't really need it. Although now that I've put this idea into
your mind be very careful to actually look for other options before trying this.

## The meta

Of course the techniques I've listed above do not cover all the cases that you
will ever meet. While I lack the ability to predict your future, I can tell you
the general state of mind that will be helpful then.

### Don't panic

Don't panic. It's a simple advice but you need to always keep it in mind. I know
how hard it is when your project is late and complex and bugs are starting to
pop up from all directions.

Don't fucking panic. You've created the software hence you've created the bugs.
They are not beyond your ability to solve, I've never ever encountered a bug
that I created which was beyond my brain power. Of course sometimes you cannot
fix it for whatever reason but at least you will be able to understand it and go
around it.

You need to stay very factual. Don't hesitate to log everything you do into a
notebook to make sure that your memory doesn't fail you. Be aware that a bug
could have many consequences out of domino effect. Remember that you are using
some data that was created by a buggy code then maybe some effects of that bug
will persist even though you fixed it. Don't hesitate to clean up everything and
start again. Methodically and calmly.

And of course, don't multi-task. If you're in an intense debugging session where
everything seems to fail, identify the most problematic bug and fix it first.
Then identify the second one and continue. Stay calm, keep notes and move
forward.

### Go to sleep

I've factually solved the hardest problems of my career simply by going to bed.
Sleep is paramount:

-   When you're tired your IQ simply goes down because your brain needs some
    rest.
-   All your thoughts are re-indexed during sleep. When you wake up, the
    complexity of looking relevant ideas up is decreased by a lot.
-   Beyond that, all brain functions perform better when rested. By example
    &mdash; and that's particularly true if you've got ADHD &mdash; the ability
    to organize.

Often when the day is ending and I'm getting stuck on some stupid things I just
close my computer, go home, enjoy my evening, sleep and go back to work the day
next. Then I'll open my computer, see the problem, realize that the solution is
in fact very simple and get on with my day.

Getting sleep when you need it &mdash; even in the middle of the day &mdash; is
going to get you much more productive than losing hours stuck dry out of ideas
and pushing your body into long hours at night.

Let's stay pragmatic though, don't take a nap every time you receive an
exception, but knowing when your brain needs rest will definitely resolve many
bugs by itself.

## Conclusion

While most of these guidelines are dedicated to avoiding bugs, now was the time
to consider how to fix the bugs when they present themselves. Sometimes the
problem is obvious, sometimes it seems evasive. Yet, it's always a tiny
condition or typo somewhere in your code that breaks everything. Changing single
line will often resolve the problem. The only question is: which line.

The answer is that if yous stay calm and methodical, there is plenty of tools
for you to apply. Of course not all the tools
