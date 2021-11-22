# Exceptions handling

Every time your program crashes it's because of an exception. Are they bad? Is
their purpose to ruin your life?

Of course not, they're a great help!

Imagine this: you're a program and something exceptional happens. Something you
were not designed to deal with. And possibly that there no way to deal with.
What do you do? Well, you raise an exception of course.

Will this crash the program? Most likely. Is it desirable? Well, imagine that
you're fetching some data from an API but in the end there is no Internet
connection. There is no possible way to make this information appear otherwise.
Obviously you need to crash.

Of course maybe you don't want the whole computer to shut down at the slightest
issue. That would be a pretty fucking bad experience. Even in SNES games gave
you several chances at failure before bringing you back to the start of the game
(unless your little brother kicked the console, if you know you know).

Let's dive into the marvelous world of exceptions!

## How it works

Everyone knows but let's still go over this. In JavaScript it would look like
that:

```javascript
try {
    // Do something
} catch (e) {
    // Handle failure
} finally {
    // Do something no matter what
}
```

What happens in the `try` block is what you're trying to do. It's what you would
do in a perfect world where everything happens like you expect it to.

Now, sometimes things go wrong. That's what the `catch` block is here for. If
you need to do something in case of an exception, that's where you need to do
it. Let's just note that it's probably less important than you think it is.

And then no matter if the things went right, wrong or even if you did a return,
the `finally` block will be executed. It's a great place to be sure that you're
closing resources. Let's just note that it's probably more important than you
think it is.

## Reasons for exceptions

Almost (?) every single operation that you do on a computer **can** and **will**
fail. And every one of those failures will raise an exception (well if the
language supports it, otherwise you'll just have to write the exceptions
handling manually for every single function call).

Here is a far-from-exhaustive list of exception reasons:

-   You're trying to connect to the Internet but the connection doesn't work
-   You're trying to read from an API but the API is drunk
-   You're trying to get more memory but the computer won't let you
-   You're trying to get more memory but the computer won't let you and on top
    of that finds you very greedy and kills you
-   You're dividing a number by zero
-   You have a typo in an API field name because you don't have spell-checking
    enabled when you write your code
-   Some value is undefined and you're expecting that it is
-   You're trying to read a file that's stored on a cheap USB stick that has
    been dead for 3 years already
-   The user tried to kill you
-   etc

Only one thing is for sure: the computer will always find new ways to fail for
reasons that go completely beyond your imagination and you'll have to deal with
it even though you can't predict it. You need to **plan for failure**.

## Dealing with exceptions

Since exceptions are unavoidable, how do we deal with them?

### Open resources

It is very important to finish what you started, not only in Hollywood
blockbusters but also when dealing with resources and operations. There are many
things that you need to deal with:

-   Open files
-   Database transactions
-   Network sockets
-   Temporary files
-   etc

When you work with a temporary file, no matter if your operation succeeded or
not you _need_ to delete it when you're done with it, otherwise it would pile up
and eat up all the available disk space. In order to make sure of this, there
are several ways.

The first and most obvious way of doing so is to make sure you always use the
`finally` block:

```python
from tempfile import NamedTemporaryFile

f = NamedTemporaryFile()

try:
    f.write('hello')
finally:
    f.close()
```

No matter if the read operation will succeed or fail, the file _will_ be closed
and deleted in the end.

Now in Python there is something even better than this. Using the
[`with`](https://docs.python.org/3/reference/compound_stmts.html#with)
statements and context managers, libraries can provide a replacement to common
`try`/`catch`/`finally` patterns. The above example is equivalent to:

```python
from tempfile import NamedTemporaryFile

with NamedTemporaryFile() as f:
    f.write('hello')
```

That's much easier to write and does exactly the same thing. Moreover, context
managers have the opportunity to deal with exception in their own way. For
example, Django will let you deal with transactions this way:

```python
with atomic():
    m = SomeModel.objects.get(pk=42)
    m.do_something()
    m.save()
    m.do_something_else()
    m.save()
```

In this code, if `do_something_else()` fails then Django will know that it also
needs to cancel the DB transaction, effectively canceling what happened with
`do_something()`.

### Catching

Now that's nice but don't you need to `catch` those exceptions?

The general advice is: not by default. By default, just let the exception bubble
up to the top and see what happens.

Frameworks like Django will catch exceptions at their level and report them.
Since they work on a per-request basis, most of the time if something fails then
it means that the response should be aborted anyways.

All uncaught exceptions should be reported to a tool,
[Sentry](https://sentry.io/) in our case. This lets us know all the errors that
happened and figure what we can do to avoid them from happening in a first
place. Said in another way: if the error happened it's too late, the code
already has a bug, all you can do is let yourself know that something is wrong
so it doesn't happen in the future.

```{note}
On the other hand, if the exception is caught and not reported not only the
user won't get the result they expected and on top of that you won't know that
something failed. You should **never** fail silently, at least not without
a report in Sentry.
```

### Reporting

However sometimes you want something nicer than an error 500 or a big panic
screen displayed to the user. In those cases, you'll be using the
`catch`/`except` block and then deal with it:

-   Still report it to Sentry (unless there is really no point to that). The SDK
    lets you
    [manually report exception](https://docs.sentry.io/product/sentry-basics/guides/integrate-backend/capturing-errors/#handled-errors)
    (or
    [messages](https://docs.sentry.io/product/sentry-basics/guides/integrate-backend/capturing-errors/#capture-message))
    when you want.
-   Report it to the user with a toast (or something alike) saying that we're
    sorry but something went wrong
-   If the exception happens during an asynchronous operation (a Celery task for
    example), store all the details of the failure and plan for a way to show it
    to the user later on. Give them a way to retry manually.

Usually this happens at a higher level. On the client side, it will tend to be
managed in the page, not the component. On the server side, maybe your whole
view is wrapped in a `try`/`except` block that will carefully cancel the
intended operation if it fails.

Meaning that deep down in your code, inside a component or inside a library, you
have zero interest in dealing with exceptions. You can definitely throw them but
you need to let the upper layers deal with them, because it's the upper layers
that talk to the user and that know what to do with a failure.

### Semantic exceptions

The whole Python standard library has 65 exception. That's not a lot, knowing
all that there is in the Python library. It's not very interesting to go super
specifically into defining exception schemes, what matters is knowing what
you're going to do with that exception.

-   A lot of public libraries and parts of the code will expect some exception
    types to mean something. For example the `argparse` module will understand
    when an argument type emits a `ValueError`.
-   You might want to use exceptions to have an easy way to display fatal errors
    to the user. This is particularly true in a CLI program. You can have a
    custom exception for errors like "File X does not exist", which gets printed
    nicely, and then for other kinds of exceptions just print the stack trace
    because it's a "real" bug.
-   You can also use exceptions as a way to communicate with the caller.
    Django's `Model.objects.get()` will raise a `DoesNotExist` exception if the
    entry does not exist, now you might want to use this as a part of the
    process.

Overall, don't complicate your life :)

## Emitting exceptions

In your code you will often have to take the decision of how to report errors
and if you should emit an exception or not. As exceptions often cause the
program to crash, we associate exceptions to pain and suffering, avoiding them
like the plague.

But as you've seen above, exceptions are our friend. They allow you to deal with
unexpected situations. As long as the handling of said exceptions is done
properly at a higher level, you can feel free to throw as many exceptions as you
need.

For example, this code gets something from an API:

```python
import httpx

resp = httpx.get('https://some-api.com')
data = resp.json()

print(data.get('someFieldThatShouldBeThere'))
```

What will happen if `someFieldThatShouldBeThere` is not there? You'll just print
`None` and this can have several side effects:

-   It can be confusing to see `None` printed instead of whatever you expect,
    and while the current setup looks trivial, in real life this can throw you
    off-track for hours if you're not careful
-   But most of all, you don't know that something on which you're relying
    actually is missing.

If instead you did this:

```python
import httpx

resp = httpx.get('https://some-api.com')
data = resp.json()

print(data['someFieldThatShouldBeThere'])
```

Then magically if the field isn't there then you'll get a full-blown exception
and you'll know that something is messed up.

What is the way to deal with that exception:

-   Either this field is not actually mandatory and you can implement a default
    behavior
-   Either this field is really necessary for you code to run and then you need
    to let the exception bubble up

Programming languages provide free sanity checks, it's great to make use of that
fact. The same concept applies to many things: when you convert an int but the
source string is invalid, when you open a file that does not exist, when you
call a method on the wrong object, etc.

Said another way: the only way to get rid of exceptions is to make your code
work correctly. If you're getting exceptions during normal operational
conditions then you have a bug and you know it.

This also means that, as much as you are happy to have the language check things
for you, don't hesitate to check things for your calling function as well. The
NASA power of 10 rules state that you should do at least 2 assertions per
function call. If you make any assumption on the inputs of your function, don't
hesitate to check them.
