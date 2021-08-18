# Documentation

Documentation is the number one thing that gets blamed when a project is late.
Typically: "oh no I need to work on this horrible horrible legacy code that
doesn't even have documentation this is going to take 10 times more time".

It is very important to write a decent documentation on all the code you write
in order to avoid in case of scenarios:

-   It will help the future developer working on your code understand what your
    code is doing and why it is doing it
-   It will advocate for your code and explain why maybe it looks like crap but
    there was not actually too many other options
-   Will it take you time to write documentation? Yes, a bit. But this time will
    be gained tenfold in the future. As you're working in WITH you probably
    already saved a lot of time because the documentation was written
-   And finally, writing the documentation and explaining your code makes you
    realize all the bugs and all the things that you've forgotten

```{warning}
If a piece of code is not documented properly it is considered to be a bug. It
does not matter how late you are. If your code gets merged into develop without
a proper documentation that's a bug.
```

## What needs to be documented

Everything.

### Macro

A macro documentation needs to be written in order to give pointers to
understand the code and how it works internally. This is usually located in the
project's `README.md` file.

A typical summary would include:

-   2 or 3 lines to describe the project, this specific component of the project
    and how it relates to other components
-   Technical requirements to run the project (language version, operating
    system, etc.)
-   Basic instructions to set up the project locally (install dependencies with
    `npm i`, start with `npm run dev`)
-   List common maintenance tasks (updating dependencies, compiling static
    assets, etc.)
-   Configuration and environment variable values
-   Links to more specific parts of the documentation (still as `.md` files)
    which describe a given feature/domain of the application (how to send
    emails, what manages the publication of pages, etc.)

No need to re-document public tools, however give a useful list of the patterns,
habits and tools that you're using for this project. You can see for example the
[CAMC2 README](https://gitlab.com/with-madrid/caps/camc2/website).

### Features/domains

As mentioned above, there is a macro documentation that serves to give pointers
and for each feature/domain of the app there is a specific documentation file
stored by example as a `.md` file within the `doc` folder at the root of the
repo.

The goal of those files is to answer a few questions:

-   What are the main pieces of code to dig into to alter this feature?
-   For anticipated possible changes what would be the procedure to follow?

There is no need for those files to be big but put yourself in the shoes of a
developer that doesn't know the project and that needs to alter this feature.

```{note}
Sometimes you have complexe sequences happening in your code. By example many
pieces of the software will communicate with one another in a specific order.
To make things clearer for the reader, you can make use of UML sequence
diagrams (using [Lucid Charts](https://www.lucidchart.com/) by example) that
you'll embed into the documentation as an image.
```

### Micro

The global idea is that everything gets documented: functions, classes, CSS
selectors, etc.

What matters most is not to explain what that piece of code does (which should
be self-evident if the name and the structure are good) but rather:

-   Why does this code exist?
-   What other pieces of code rely on this?
-   What assumptions did you make?
-   You used a dirty hack, why?
-   What are the business constraints?

It's not always needed to write a full page of documentation for each piece of
code, but you need to cover all of those points if there is anything to say
about them (or if not, just mention it)

#### Python

Fortunately, documentation is a core feature of Python and embedded into the
language as "docstrings". Unfortunately, this feature is not standardized and
the content of docstrings can vary from project to project.

##### Docstrings

We use the
[NumPy style](https://numpydoc.readthedocs.io/en/latest/format.html#docstring-standard)
of docstrings for our projects. This is not usually the default one in IDEs but
can easily be configured into development tools. The reason of this non-default
choice is simply that "traditional" RST doc is un-fucking-readable.

There is one interpretation in the NumPy style that we do. We'll see later that
we use a lot of type annotations. This makes specifying the types into the
docstring completely counter-productive. As the NumPy style does not make types
mandatory, we consider that types must never be specified in the docstring and
must rather be specified through type annotations.

```{note}
PyCharm will often add a `Returns` section by default to your doc. It is not
expected to be a descriptive text but rather is supposed to be the return type
of that function. Since we don't specify types in docstrings, this section must
be removed.
```

##### Type annotations

One of the most interesting "recent" features of Python is
[type annotations](https://docs.python.org/3/library/typing.html). They are not
checked at runtime but are a very powerful tool to document the code and what
you expect as an input/output of your function. They are not covering 100% of
use cases (especially on generics) but as long as you are not in the 0.01% of
cases which can't be expressed using annotations you must always specify them.

Let's note that type annotations come with
[`NamedTuple`](https://docs.python.org/3/library/typing.html#typing.NamedTuple),
[dataclasses](https://docs.python.org/3/library/dataclasses.html) or even
[`TypedDict`](https://docs.python.org/3/library/typing.html#typing.TypedDict).
They are powerful ways to express complex structures while documenting them
properly.

The added benefit of these annotations is that they will help decent IDEs a lot
to understand your code and help you with auto-completion. If the auto-complete
is not providing useful hints then probably your annotations are wrong.

##### Example

Here is a small example of a properly documented class.

```python
from typing import Union, NamedTuple
from enum import Enum


# shortcut for number types
number = Union[int, float]


class OpType(Enum):
    """
    This is all the useless operations that you can do in UselessMathClass
    """

    add = "add"
    subtract = "subtract"


class OpOutput(NamedTuple):
    """
    Contains the parameters and the output of useless operations as done by
    UselessMathClass
    """

    type: OpType
    a: number
    b: number
    out: number


class UselessMathClass:
    """
    Uselessly implements math operations that are already embedded into the
    language, but this is just an example for some documentation about
    documentation.

    Notes
    -----
    Because we want to be fancy and demonstrate that you can have complex
    return types using NamedTuple, these operations will return the OpOutput
    type which contains both the output and the arguments of the operation, by
    example if you want to remember what you added together later on (hey you
    never know).

    Attributes
    ----------
    is_useless
        Indicates if this instance is useless (short answer: yes)
    """

    def __init__(self):
        """
        Creates an attribute to this instance so that I can demonstrate the
        Attributes section in the docstring of the class.
        """

        self.is_useless = True

    def add(self, a: number, b: number) -> OpOutput:
        """
        Does a regular math addition, because I need to show you some code and
        docstrings.

        Notes
        -----
        As it is an addition, you can invert a and b easily

        Parameters
        ----------
        a
            The left-hand side of the operation
        b
            The right-hand side of the operation
        """

        return OpOutput(OpType.add, a, b, a + b)

    def subtract(self, a: number, b: number) -> OpOutput:
        """
        Does a regular math subtraction, because I need to show you some code
        and docstrings.

        Notes
        -----
        As it is a subtraction, be careful of the order of a and b, unless you
        are a mentally unstable person or try to become one.

        Parameters
        ----------
        a
            The number that b is going to be subtracted to
        b
            The number that you will subtract from a
        """

        return OpOutput(OpType.subtract, a, b, a - b)
```

#### JavaScript

Since in JS everything is object that's a bit complicated but let's start with
the simplest, using JSDoc.

```javascript
/**
 * This does a bloody addition because I ain't got no new ideas since the
 * Python section, all right?
 *
 * @param {Number} a - The left-hand side of the operation
 * @param {Number} b - The right-hand side of the operation
 * @returns {Number}
 */
function add(a, b) {
    return a + b;
}
```

As you can see, we try to give some sense to our function as well as to give
some types. It can quickly become tedious to document complex types, but it's
always appreciated when it's done.

Next let's review some part of a hypothetical Vue component.

```javascript
/**
 * That's kind of a mock component that doesn't even have a render function but
 * this is just for the example.
 */
export default {
    data() {
        return {
            /**
             * That's the foo variable which holds the foo value. Anyways it's
             * juts here for the example but you get the idea.
             */
            foo: "bar",

            /**
             * Yes I wasn't going to let just one variable another one is good
             * to show that indeed you need to comment each one of them.
             */
            baz: "foo",
        };
    },

    computed: {
        /**
         * Live-generating the value of foo and baz together, because I can.
         * @returns {string}
         */
        together() {
            return `${this.foo} ${this.baz}`;
        },
    },

    methods: {
        /**
         * Trying to raise the bar
         */
        beBarBaric() {
            this.foo = "barbar";
        },
    },
};
```

As JS is pretty flex it would be hard to describe all the rules for all the
frameworks but let's remember this simple rule: document everything.

#### CSS

Interestingly enough, we spend a very significant part of our time writing CSS
and yelling at Internet Explorer and doing weird hacks so that it works in
Safari, but this industry doesn't really care about documenting CSS. Well CSS is
real code and as such requires real documentation.

The concept is simple. Document everything.

So basically, CSS groups instructions under selectors. They control DOM nodes
that are positioned in relation to one another using a gazillion of techniques.

What is interesting to mention in a CSS documentation is:

-   How and in relation to what is this node expected to be positioned?
-   What kind of pain you went through trying to make this work for Safari?

For example:

```css
/**
 * We want to position the inside in the center so we remove the default
 * margin/padding and we hide the potential sub-pixel overflows that might
 * trigger a scrollbar.
 */
body,
html {
    margin: 0;
    padding: 0;
    overflow: hidden;
}

/**
 * The thing's size is limited by the screen width. The content will have to
 * wrap.
 *
 * Also it is centered vertically and horizontally on the screen using an
 * absolute position (relative to the body) and the translate -50% hack.
 */
.thing {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 60vw;
}
```

Another way to express things in CSS is to use pre-processor variables when you
make computations. This is a simple way to express how you obtained that value
and what is the meaning of that computation.

```scss
$gutter-size: 20px;

/**
 * Simple CSS grid, see https://dev.to/xowap/css-patterns-deep-dive-in-grids-4kh6
 * The negative margin compensates the padding applied to the cells in order to
 * create a gutter of the specified dimension.
 */
.grid {
    display: flex;
    flex-wrap: wrap;
    margin: -($gutter-size / 2);
}

/**
 * Simply a cell of the grid with a padding that serves to create a gutter
 * between cells.
 */
.cell {
    padding: ($gutter-size / 2);
}
```

#### HTML

Feel free to use HTML comments to describe the structure of your code but the
best option is still to keep your CSS close and rely on CSS selectors to explain
what the HTML code is about.

## When to write documentation?

Before each commit it is a good idea to look at the diff and inspect every
little detail of what you're going to commit. Make sure that all the things you
wrote are somehow document at micro/domain/macro levels.

A typical commit workflow would be:

1. Check that everything has docstrings
2. Realize that not
3. Write some docstrings
4. Realize that some function has a bug because explaining it made it clear
5. Fix the bug
6. Update the docstring of the function that had a bug
7. Realize you can refactor some things
8. Refactor things
9. Change the documentation
10. Re-read everything
11. Write missing docstrings
12. Re-read everything
13. Re-read everything just to be sure
14. Ok commit now

Don't hesitate to write documentation even if:

-   This function did not previously have documentation (but maybe put this in a
    different commit)
-   This function was not written by you
-   You are late on your delivery
-   The Apocalypse AND Armageddon are supposed to happen in 5 minutes

Overall, it is a daily job to fight against the lack of documentation. It's up
to everyone to write the documentation they would like to read.
