# NASA's power of 10

```{note}
This was initially an article published on
[dev.to](https://dev.to/xowap/10-rules-to-code-like-nasa-applied-to-interpreted-languages-40dd).
This will explain the slight change of tone between this page and the others.
```

> _Foreword_ &mdash; Dear beginner, dear not-so-beginner, dear reader. This
> article is a lot to take in. You'll need perspective for it to make sense.
> Once in a while, take a step back and re-think about all the concepts
> explained here. They helped me a lot over the years, and I hope that they will
> help you too. This article is my interpretation of them for the work I do,
> which is mostly web-related development.

NASA's [JPL](https://en.wikipedia.org/wiki/JPL), which is responsible for some
of the most awesomest science out there, is quite famous for its
[Power of 10](https://en.wikipedia.org/wiki/The_Power_of_10:_Rules_for_Developing_Safety-Critical_Code)
rules ([see original paper](http://spinroot.com/gerard/pdf/P10.pdf)). Indeed, if
you are going to send a robot on Mars with a 40 minutes ping and no physical
access to it then you pretty damn well should make sure that your code doesn't
have bugs.

These rules were made with embedded software in mind but why wouldn't everybody
be able to benefit from this? Could we apply them to other languages like
JavaScript and Python &mdash; and thus make web applications more stable?

That's a question I have been considering for years and here is my
interpretation of the 10 rules applied to interpreted languages and web
development.

## 1. Avoid complex flow constructs, such as goto and recursion.

> **Original rule** &mdash; Restrict all code to very simple control flow
> constructs – do not use `goto` statements, `setjmp` or `longjmp` constructs,
> and direct or indirect recursion.

When you use weird constructs then your code becomes difficult to analyze and to
predict. The generations that came out after
[`goto` was considered harmful](https://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf)
did indeed avoid using it. We're at the stage where we're debating if
[`continue` is `goto`](https://github.com/airbnb/javascript/issues/1103) and
thus should be banned.

My take on this is that `continue` in a loop is exactly the same as `return` in
a `forEach()` (especially now that JS has block scoping) so if you're saying
that `continue` is `goto` then you're basically closing your eyes on the issue.
But that's a JS-specific implementation detail.

As a general rule you should avoid everything that is mind-bending or hard to
spot because if your brain power is spent understanding the quirks of jumping
around then you're not spending it on the actual logic and then you might be
[hiding some bugs](https://www.youtube.com/watch?v=vJG698U2Mvo) without your
knowledge.

I'll let you be the judge of what you put in that category but I would
definitely put:

-   `goto` itself of course
-   PHP's
    [`continue`](https://www.php.net/manual/en/control-structures.continue.php)
    and [`break`](https://www.php.net/manual/en/control-structures.break.php)
    used in conjunction with numbers, which is just pure insanity
-   `switch` constructs, because they usually require a `break` to close the
    block and I guarantee you that there _will be_ bugs. A series of
    `if`/`else if` will do the same job in a non-confusing manner

Besides this, avoid of course recursions, for several reasons:

-   As they build on the call stack, whose size is very limited, you can't
    really control how deep your recursion can go. Even if your code is legit,
    it might fail because it recurses too much.
-   Do you get this feeling when doing recursions where you don't really know if
    your code is ever going to stop? It's very hard to imagine a recursion and
    to prove that it will stop correctly at the end.
-   It's also more compatible with the following rules to use an iterative
    algorithm instead of a recursive one, because you have more control (again)
    on the size of the problem you're dealing with

As a bonus, recursions can often come as an intuitive implementation of an
algorithm but is usually also far from optimal. By example we often ask in job
interviews to implement the factorial function using a recursive function but
that's far less efficient than an iterative implementation. Regular expressions
too
[can be disastrous](https://dev.to/xowap/how-cloudflare-could-have-avoided-its-outage-maybe-1jko).

## 2. All loops must have fixed bounds. This prevents runaway code.

> **Original rule** &mdash; All loops must have a fixed upper-bound. It must be
> trivially possible for a checking tool to prove statically that a preset
> upper-bound on the number of iterations of a loop cannot be exceeded. If the
> loop-bound cannot be proven statically, the rule is considered violated.

The idea with this rule is the same as with the interdiction of recursions: you
want to prevent runaway code. The way you implement this is by making sure it's
trivial to prove statically that the loop won't exceed a given number of
iterations.

Let's give an example in Python. You could do this:

```python
def iter_max(it, max_iter):
    cnt = 0

    for x in it:
        assert cnt < max_iter
        yield x
        cnt += 1


def main():
    for i in iter_max(range(0, 100), 10):
        print(i)
```

A language like Python will however limit the number of iterations by itself in
many cases. So if you prove that the input lists won't be too long there is a
bunch of cases where you don't need to do this.

A good application of that is pagination: make sure that you always work with
pages that are of a reasonable size and this way you won't need loops that could
run forever. Always think your code so it only works on a finite amount of data
and let tools that were made for that handle infinity (like your DB engine).

## 3. Avoid heap memory allocation.

> **Original rule** &mdash; Do not use dynamic memory allocation after
> initialization.

This makes of course no sense in interpreted languages where literally
everything is allocated dynamically. But this doesn't mean that the rule does
not apply to them. The core idea of the rule is that, beyond the tedious memory
management techniques that you have to use in C, it's also very important to be
able to fixate an upper bound in the memory consumption of your program.

So for interpreted languages it means that when you write your code, you should
be able to know that given any accepted input the memory consumption won't go
beyond a certain point.

While this can be hard to prove in an absolute manner, there is good clues and
principles that you can follow. To be more specific and to repeat the previous
sections, pagination is an essential technique. If you only work with pages and
that you know that the content of each page is limited (DB fields have limited
length and so on) then it's quite easy to prove that at least the data coming
from those pages can be contained within an upper bound.

So once again if you use pages you'll know that the memory allocated to each
page is reasonable and that your system can handle it.

## 4. Restrict functions to a single printed page.

> **Original rule** &mdash; No function should be longer than what can be
> printed on a single sheet of paper in a standard reference format with one
> line per statement and one line per declaration. Typically, this means no more
> than about 60 lines of code per function.

This is about two different things.

First, the human brain can only fully understand so much logic and the symbolic
page looks about right. While this estimation is totally arbitrary you'll find
that you can easily organize your code into functions of about that size or
smaller and that you can easily understand those functions. Nobody likes to land
on a 1000-lines function that seems to do a gazillion things at the same time.
We've all been there and we know it should not happen.

Second, when the function is small &mdash; or rather as small as possible
&mdash; then you can worry about giving this function the least possible power.
Make it work on the smallest unit of data and let it be a super simple
algorithm. It will de-couple your code and make it more maintainable.

And let me emphasis on the arbitrary aspect of this rule. It works for the very
reason that it is arbitrary. Someone decided that they don't want to see a
function longer than a page because it's not nice to work with if it is any
longer. And they've also noticed that it is doable. At first I rejected this
rule but more than a decade later I must say that if you just follow either of
the goals mentioned above then your code will always fit in a page of paper. So
yes, it's a good rule.

## 5. Use a minimum of two runtime assertions per function.

> **Original rule** &mdash; The assertion density of the code should average to
> a minimum of two assertions per function. Assertions are used to check for
> anomalous conditions that should never happen in real-life executions.
> Assertions must always be side-effect free and should be defined as Boolean
> tests. When an assertion fails, an explicit recovery action must be taken,
> e.g., by returning an error condition to the caller of the function that
> executes the failing assertion. Any assertion for which a static checking tool
> can prove that it can never fail or never hold violates this rule. (I.e., it
> is not possible to satisfy the rule by adding unhelpful "assert(true)"
> statements.)

That one is tricky because you need to understand what would count as an
assertion.

In the original rules, assertions are consider to be a boolean test done to
verify "pre- and post- conditions of functions, parameter values, return values
of functions, and loop-invariants". If the test fails then the function must do
something about it, typically returning an error code.

In the context of C or Go it is mostly as simple as this. In the context of
almost every other language it means raising an exception. And depending on the
language, a lot of those assertions are made automatically.

To give Python as an example, you could do this:

```python
assert "foo" in bar
do_something(bar["foo"])
```

But why bother when the fact of doing this will also raise an exception?

```python
do_something(bar["foo"])
```

For me it's always very tempting to make as if the input value was _always_
right by falling back to defaults when the input is crap. But that's usually not
helpful. Instead, you should let your code fail as much as possible and use an
exception reporting tool (I personally love [Sentry](https://sentry.io/) but
there is plenty out there). This way you'll know what goes wrong and you'll be
able to fix your code.

Of course, this means that your code will fail at runtime. But it's all right!
Runtime is not production time. If you test your application extensively before
sending it to production, this will allow you to see most of the bugs. Then your
real users will also encounter some bugs, but you will also be informed of them,
instead of things failing silently.

As a side-note, if you don't have control over the input, like if you're doing
an API by example, it's not always a good idea to fail. Raise an exception on
incorrect input and you'll get an error 500 which is not really a good way to
communicate bad input (since it would rather be something in the range of the
4xx status codes). In that case you need to properly validate the input before
hand. However depending on who's using the code you might or might not want to
report the exceptions. A few examples:

-   An external tool calls your API. In that case you want to report exceptions
    because you want to know if the external tool is going sideways.
-   Another of your services calls your API. In that case you also want to
    report exceptions as it's yourself doing things wrong.
-   The general public calls your API. In that case you probably don't want to
    receive an email every time that someone does something wrong.

In short it's all about knowing about the failures that you will find
interesting to improve your code stability.

## 6. Restrict the scope of data to the smallest possible.

> **Original rule** &mdash; Data objects must be declared at the smallest
> possible level of scope.

In short, don't use global variables. Keep your data hidden within the app and
make it so that different parts of the code can't interfere with each other.

You can hide your data in classes, modules, second-order functions, etc.

One thing though is that when you're doing unit testing then you'll notice that
this sometimes backfires to you because you want to set that data manually just
for the test. This might mean that you need to hide your data away but keep a
way to change it which you conventionally won't use. That's the famous `_name`
in Python or `private` in other languages (which can still be accessed using
reflection).

## 7. Check the return value of all non-void functions, or cast to void to indicate the return value is useless.

> **Original rule** &mdash; The return value of non-void functions must be
> checked by each calling function, and the validity of parameters must be
> checked inside each function.

In C, the mostly-used way of indicating an error is by the return value of the
corresponding function (or by reference into an error variable). However, with
most interpreted languages it's simply not the case since errors are indicated
by an exception. Even
[PHP 7](https://www.php.net/manual/en/language.errors.php7.php) improved that
(even if you still get warnings printed as HTML in the middle of your JSON if
you do something non-fatal).

So in truth this rule is: let errors bubble up until you can handle them (by
recovering and/or logging the error). In languages that have exceptions it's
pretty simple to do, simply don't catch the exceptions until you can handle them
properly.

See it another way: don't catch exceptions too early and don't silently discard
them. Exceptions are meant to crash your code if needs to be and the proper way
to deal with exceptions is to report them and fix the bug. Especially in web
development where an exception will just result in a 500 response code without
dramatically crashing the whole front-end.

## 8. Use the preprocessor sparingly.

> **Original rule** &mdash; The use of the preprocessor must be limited to the
> inclusion of header files and simple macro definitions. Token pasting,
> variable argument lists (ellipses), and recursive macro calls are not allowed.
> All macros must expand into complete syntactic units. The use of conditional
> compilation directives is often also dubious, but cannot always be avoided.
> This means that there should rarely be justification for more than one or two
> conditional compilation directives even in large software development efforts,
> beyond the standard boilerplate that avoids multiple inclusion of the same
> header file. Each such use should be flagged by a tool-based checker and
> justified in the code.

In C code, the macros are a particularly efficient way to hide the mess. They
allow you to _generate_ C code, mostly like you would write a HTML template.
It's easy to understand that it's going to be used sideways and actually you can
have a look at the [IOCCC](https://www.ioccc.org/) contestants which usually
make a very heavy use of C macros to generate totally unreadable code.

However C (and C++) is mostly the only mainstream language making use of this,
so how would you translate this into other languages? Did we get rid of the
problem? Does compiling code into other code that will then be executed sound
familiar to someone?

Yes, I'm talking about the huge pile of things we put in our Webpack
configurations.

The initial rule recognizes the need for macros but asks that they are limited
to "simple macro definitions". What is the "simple macro" of Webpack? What is
the good transpiler and the bad transpiler?

My rationale is simple:

-   Keep the stack as small as possible. The less transpilers you have the less
    complexity you need to handle.
-   Stay as mainstream as possible. By example I always use Webpack to transpile
    my JS/CSS, even in Python or PHP projects. Then I use a simple wrapper
    around a manifest file to get the right file paths on the server side. This
    allows me to stay compatible with the rest of the JS world without having to
    write more than a simple wrapper. Another way to put it is: stay away from
    things like
    [Django Pipeline](https://django-pipeline.readthedocs.io/en/latest/).
-   Stay as close as possible from the real thing. Using ES6+ is nice because
    it's a superset of previous JS versions, so you can see transpiling as a
    simple layer of compatibility. I wouldn't recommend however to transpile
    Dart or Python or anything like that into JS.
-   Only do it if it brings an actual value for your daily work. By example,
    CoffeeScript is just an obfuscated version of JavaScript so it's probably
    not worth the pain, while something like Stylus/LESS/Sass bring variables
    and mixins to CSS will help you _a lot_ to maintain CSS code.

You're the judge of good transpilers for your projects. Just don't clutter
yourself with useless tools that are not worth your time.

## 9. Limit pointer use to a single dereference, and do not use function pointers.

> **Original rule** &mdash; The use of pointers should be restricted.
> Specifically, no more than one level of dereferencing is allowed. Pointer
> dereference operations may not be hidden in macro definitions or inside
> typedef declarations. Function pointers are not permitted.

Anybody who's done C beyond the basic examples will know the headache of
pointers. It's like inception but with computer memory, you don't really know
how deep you should follow the pointers.

The need for that is, by example, the
[`qsort()`](https://en.cppreference.com/w/c/algorithm/qsort) function. You want
to be able to sort any type of data but without knowing anything on them before
compiling. Have a look at the signature:

```c
void qsort( void *ptr, size_t count, size_t size,
            int (*comp)(const void *, const void *) );
```

It's one if the most frighteningly unsafe things you'll ever see in a standard
library documentation. Yet, it allows the standard library to sort any kind of
data, which other more modern language still have
[a little bit awkward](https://gobyexample.com/sorting) solutions.

But of course when you open the gate for this kind of things, you open the gate
to any kind of pointer madness. And as you know, when a gate is open then people
will go through it. Hence this rule for C.

However what about our case of interpreted languages? We will first cover why
references are bad and then we will explain how to accomplish the initial intent
of writing generic code.

### Don't use references

Pointers don't exist but some ancient and obscure languages like
[PHP](https://www.php.net/manual/en/language.references.pass.php) still thought
that it would be a good idea to have it. However, most of the other languages
will only use a strategy named
[call-by-sharing](https://en.wikipedia.org/wiki/Evaluation_strategy#Call_by_sharing).
The idea is &mdash; very quickly &mdash; that instead of passing a reference you
will pass objects that can modify themselves.

The core point against references is that, beyond being memory unsafe and crazy
in C, they also produce side-effects. By example, in PHP:

```php
function read($source, &$n) {
    $content = // some way to get the content
    $n = // some way to get the read length

    return $content;
}

$n = 0;
$content = read("foo", $n);

print($n);
```

That's a common, C-inspired, use-case for references. However, what you really
want to do in this case is

```php
function read($source) {
    $content = // some way to get the content
    $n = // some way to get the read length

    return [$content, $n];
}

list($content, $n) = read("foo");

print($n);
```

All you need is two return values instead of one. You can also return data
objects which can fit any information you want them to fit and also evolve in
the future without breaking existing code.

And all of this without affecting the scope of the calling function, which is
rather nice.

Another safety point though is when you're modifying an object then you're
potentially affecting the other users of that object. That's by example
[a common pitfall of Moment.js](https://stackoverflow.com/questions/30979178/how-do-i-work-around-mutability-in-moment-js).
Let's see.

```javascript
function add(obj, attr, value) {
    obj[attr] = (obj[attr] || 0) + value;
    return obj;
}

const a = { foo: 1 };
const b = add(a, "foo", 1);

console.log(a.foo); // 2
console.log(b.foo); // 2
```

On the other hand you can do:

```javascript
function add(obj, attr, value) {
    const patch = {};
    patch[attr] = (obj[attr] || 0) + value;
    return Object.assign({}, obj, patch);
}

const a = { foo: 1 };
const b = add(a, "foo", 1);

console.log(a.foo); // 1
console.log(b.foo); // 2
```

Both `a` and `b` stay distinct objects with distinct values because the `add()`
function did a copy of `a` before returning it.

Let's conclude this already-too-long section with the final form of the rule:

> Don't mutate your arguments unless the explicit goal of your function is to
> mutate your arguments. If you do so, do it by sharing and not by reference.

That would by example be the
[no-param-reassign](https://eslint.org/docs/rules/no-param-reassign) rule in
ESLint as well as the
[Object.freeze()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze)
method. Or in Python you can use a
[NamedTuple](https://docs.python.org/3/library/typing.html#typing.NamedTuple) in
many cases.

Note on performance: if you change the size of an object then the underlying
process will basically be to allocate a new contiguous region of memory for it
[and then copy it](https://en.cppreference.com/w/c/memory/realloc). For this
reason, a mutation is often a copy anyways, so don't worry about copying your
objects.

### Leverage the weak-ish dynamic typing

Now that we closed the crazy door of references, we still need to write generic
code if we want to stay
[DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself).

The good news is that while compiled languages are bound by the rules of physics
and the way computers work, interpreted languages can have the luxury of putting
a lot of additional support logic on top of that.

Specifically, they mostly rely on
[duck typing](https://en.wikipedia.org/wiki/Duck_typing). Of course you can add
some level of static type checking like
[TypeScript](https://www.typescriptlang.org/), Python's
[type hints](https://docs.python.org/3/library/typing.html) or PHP's
[type declarations](https://www.php.net/manual/en/functions.arguments.php#functions.arguments.type-declaration).
Using the wisdom of other rules:

-   Rule 5 &mdash; Make many assertions. Expecting something from an object
    which doesn't actually have it will raise an exception, which you can catch
    and report.
-   Rule 10 &mdash; No warnings allowed (explained hereafter). Using the various
    type checking mechanisms you can rely on a static analyzer to help you spot
    errors that would arise at runtime.

Those two rules will protect you from writing dangerous generic code. Which
would result in the following rule

> You can write generic code as long as you use as many tools as possible to
> catch mistakes, and especially you need to follow rules 5 and 10.

## 10. Compile with all possible warnings active; all warnings should then be addressed before release of the software.

The initial full rule is:

> All code must be compiled, from the first day of development, with allcompiler
> warnings enabled at the compiler’s most pedantic setting. All code must
> compile with these setting without any warnings. All code must be checked
> daily with at least one, but preferably more than one, state-of-the-art static
> source code analyzer and should pass the analyses with zero warnings.

Of course, interpreted code is not necessarily compiled so it's not about the
compiler warnings _per se_ but rather about getting the warnings.

There is fortunately a great amount of warning sources out there:

-   All the [JetBrains IDEs](https://www.jetbrains.com/idea/) are pretty awesome
    at finding out issues in your code. Recently, those IDE taught me a lot of
    patterns in different languages. That's really the main reason why I prefer
    something like this to a simplistic code editor: the warnings are very smart
    and helpful.
-   Linters for all the languages
    -   JavaScript &mdash; [eslint](https://eslint.org/) with a set of rules
        [AirBnB](https://github.com/airbnb/javascript) maybe?
    -   Python &mdash; There is a
        [bunch of tools](https://realpython.com/python-code-quality/#linters)
        that will help you either with type checking or with code smells
        detection
-   Automated code review tools like [SonarQube](https://www.sonarqube.org/)
-   Spell checkers are also surprisingly important because they will allow you
    to sniff out typos regardless of type analysis or any complicated static
    code analysis. It's a really efficient way to not lose hours because you
    typed `reuslts` instead of `results`.

The main thing about warnings is that you **must** train your brain to see them.
A single warning in the IDE will drive me mad while on the other hand I know
people that just _won't see_ them.

A final point on warnings is that on the contrary of compiled languages,
warnings here are not always 100% certain. They are more like 95% certain and
sometimes it's just an IDE bug. In that case, you should explicitly disable the
warning and if possible give a small explanation of why you're sure that you
don't need to apply this warning. However, think well before doing so because
usually the IDE is right.

## Key takeaways

The long discussion above tells us that those 10 rules were made for C and while
you can use there philosophy in interpreted languages you can't really translate
them into 10 other rules directly. Let's make our new power of 10 + 2 rules for
interpreted languages.

-   **Rule 1** &mdash; Don't use `goto`, rationalize the use of `continue` and
    `break`, don't use `switch`.
-   **Rule 2** &mdash; Prove that your problem can never create runaway code.
-   **Rule 3** &mdash; To do so, limit the size of it. Usually using pagination,
    map/reduce, chunking, etc.
-   **Rule 4** &mdash; Make code that fits in your head. If it fits in a page,
    it fits in your head.
-   **Rule 5** &mdash; Check that things are right. Fail when wrong. Monitor
    failures. See rule 7.
-   **Rule 6** &mdash; Don't use global-ish variables. Store data in the
    smallest possible scope.
-   **Rule 7** &mdash; Let exceptions bubble up until you properly recover
    and/or report them.
-   **Rule 8** &mdash; If you use transpilers, make sure that they solve more
    problems than they bring
-   **Rule 9.1** &mdash; Don't use references even if your language supports it
-   **Rule 9.2** &mdash; Copy arguments instead of mutating them, unless it's
    the explicit purpose of the function
-   **Rule 9.3** &mdash; Use as many type-safety features as you can
-   **Rule 10** &mdash; Use several linters and tools to analyze your code. No
    warning shall be ignored.

And if you take a step back, all of those rules could be summed up in one rule
to rule them all.

> Your computer, your RAM, your hard drive even your brain are bound by limits.
> You need to cut your problems, code and data into small boxes that will fit
> your computer, RAM, hard drive and brain. And that will fit together.
