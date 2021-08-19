# Functional thinking

What made popular frameworks like Angular, Vue, Svelte, etc. is the fact that
they changed the paradigm in comparison to the "old" JavaScript frameworks like
jQuery very obviously their declarative template approach. Now, regardless of
how it is implemented under the hood, this definitely shows a paradigm shift
from Imperative to Functional.

[Imperative](https://en.wikipedia.org/wiki/Imperative_programming) will be more
"if this happens then do this and that" while
[Functional](https://en.wikipedia.org/wiki/Functional_programming) will rather
be "here is how to transform the data to reach the expected result".

## Functions

In this case "function" still means a programming function but with a thought
pattern and use cases that are closer to what mathematicians call functions. You
know, things like that:

```{math}
   \begin{eqnarray}
      f_1(x)    & = & ax^2 \\
      f_2(x)    & = & bx \\
      f_3(x)    & = & c \\
      f(x)      & = & f_1(x) + f_2(x) + f_3(x)
   \end{eqnarray}
```

In the example above we cut down simple functions and compose them with an
addition in order to create a polynomial expression. You can sort of imagine
that the value of `x` is flowing through those functions to be transformed into
the final result.

## Functional vs Imperative

This summary
[stolen from Microsoft](https://docs.microsoft.com/en-us/dotnet/standard/linq/functional-vs-imperative-programming)
gives us an overview of the compromises which come with each paradigm:

| Characteristic            | Imperative approach                                                  | Functional approach                                                |
| ------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Programmer focus          | How to perform tasks (algorithms) and how to track changes in state. | What information is desired and what transformations are required. |
| State changes             | Important.                                                           | Non-existent.                                                      |
| Order of execution        | Important.                                                           | Low importance.                                                    |
| Primary flow control      | Loops, conditionals, and function (method) calls.                    | Function calls, including recursion.                               |
| Primary manipulation unit | Instances of structures or classes.                                  | Functions as first-class objects and data collections.             |

So which approach is the best? I guess you guessed: it depends.

### Imperative

If you're doing server-side stuff, like by example a Django view, then there is
no question that imperative is the simplest way to go there. You can express the
rendering of a view more or less like that:

1. Request received
2. Fetch the object requested
3. Put the object in a serializer
4. Transform into JSON
5. Return transformed JSON

This is very nice and simple, also this is how we were taught to code in school
for most of us.

### Functional

However on the front-end things are different. Imagine that you have a list of
elements with a search bar to filter them. Obviously you'll want to refresh the
list when the user types a search query and you're getting the results from the
API.

The first challenge is rendering the HTML itself. Where do you get the template
from? Do you create it on server and on JS side? Do you create it by creating
DOM elements one by one in jQuery? This is very tedious to do. That's where SPAs
and declarative templates came in handy.

Now how do you handle state changes? With jQuery you have to select the list,
empty it, create the DOM of the loader, display it, wait for the query to finish
loading, remove the loader, create the DOM for the new list... This is
incredibly tedious and making mistakes is crazily easy. You can quickly end up
with a loader still displayed on top of a loaded list because the user did two
actions at the same time.

This is when functional comes into play

-   On one side you have the data you want to display. The content of the list,
    the loading status, what did the user type into the search bar, etc
-   On the other side you have the DOM which is displayed to the user

All you need is to make the link between your data and the DOM. This is what
frameworks like Vue are doing: they give to your functions the data, your
function generates the expected output and then Vue computes the changes it
needs to apply to the DOM.

At this stage, it would be interesting for you to watch at least the first 7
minutes of the following video:

```{eval-rst}
.. raw:: html
   :file: reactivity.html
```

To quote the most important part of this presentation:

> Reactive programming is all about data flows. It's all about tracking values
> through your application. When the value changes, your application should
> react.

In other words, when using a reactive framework like Vue or Svelte, you need to
worry about 2 things:

-   Maintaining your data up to date (bindings, methods and events)
-   Providing a transformation of this data which translates into DOM (templates
    and computed properties)

## A simple demo

Let's try to demonstrate how using functional patterns make the code simple to
understand and manage.

The goal of this example is to demonstrate how you can manage a list of elements
that changes dynamically onto which you want a live case-insensitive search. You
can try it out on the
[code sandbox](https://codesandbox.io/s/functional-demo-jojl6).

```html
<template>
    <div id="app">
        <div>Query: <input type="text" v-model="query" /></div>

        <ul>
            <li v-for="item of results" :key="item.id">{{ item.name }}</li>
        </ul>

        <form @submit.prevent="addItem">
            Add item: <input type="text" v-model="newItem" /><button
                type="submit"
            >
                Add
            </button>
        </form>
    </div>
</template>

<script>
    export default {
        data() {
            return {
                /**
                 * Items that can be searched.
                 *
                 * Let's note that the generation of full objects is done in a
                 * map because I was lazy to type all of them individually. I
                 * hope this doesn't hurt clarity.
                 */
                items: ["Foo", "Bar", "Baz", "Hello", "Item"].map((x, id) => ({
                    name: x,
                    id,
                })),

                /**
                 * Current search query (bound to input)
                 */
                query: "",

                /**
                 * New item's name (bound to input)
                 */
                newItem: "",
            };
        },

        methods: {
            /**
             * Appends an item to the list and clears the form.
             */
            addItem() {
                this.items.push({ name: this.newItem, id: this.nextId });
                this.newItem = "";
            },
        },

        computed: {
            /**
             * Vue lists need an ID to work. That's why we add an ID to our
             * objects. The next available ID is simply the previous ID
             * incremented by one. This function takes care to compute that.
             * Re-computation happens when the list changes and only then.
             */
            nextId() {
                return Math.max(...this.items.map((x) => x.id)) + 1;
            },

            /**
             * We normalize the query to facilitate searching in a
             * case-insensitive way
             */
            normalizedQuery() {
                return this.query.toLowerCase();
            },

            /**
             * As items can be searched in a case-insensitive way, this is a
             * mirror of the items list which contains all of them normalized
             * to lower case. Instead of doing a lower-case search every time
             * the user types, the "index" is pre-generated and automatically
             * mirroring the list of items.
             */
            normalizedItems() {
                return this.items.map((x) => ({
                    ...x,
                    normalizedName: x.name.toLowerCase(),
                }));
            },

            /**
             * Results list of all items that contain the normalized query,
             * computed as the user types.
             */
            results() {
                return this.normalizedItems.filter((x) =>
                    x.normalizedName.includes(this.normalizedQuery)
                );
            },
        },
    };
</script>
```

You can try to imagine how this code would work without the help of a functional
structure. Look a the dependency graph of the filtered list of elements:

-   `results`
    -   `normalizedItems`
        -   `items`
            -   (can be changed by user input)
    -   `normalizedQuery`
        -   `query`
            -   (can be changed by user input)

This means that for a bit of code as simple as this, two different user inputs
can cause `results` to change. This means that you have two event handlers whose
goal is to change the value inside `results`. You can try to code it for fun, it
is really easy to get lost with this kind of logic.

Of course the day someone comes in and asks you to change the filters then you
have even more inputs that can modify `results`. If you have a functional
approach, all you'll have to change is `results()`. If you have an imperative
approach, you will make the hair growth industry rich.

## General approach

Of course not all is black and white. By example in an OO/imperative paradigm
you will still find functional ideas like the
[Visitor](https://en.wikipedia.org/wiki/Visitor_pattern) pattern. However, it is
advised to familiarize yourself with both ways of thinking in order to be able
to use the best option for the current task:

-   One-off request-type operations like handling request in Django is much
    easier to do in an imperative way
-   Complex data manipulation, filtering and interaction is often easier to make
    with a functional approach

For our projects, it is important to use Vue's functional tools as much as
possible:

-   Computing derived values using computed functions
-   Using Vue's native input binding
-   Using events and methods only to modify the state...
-   And letting the data trickle down the functions into the DOM

And most importantly: please avoid until absolutely necessary to modify the DOM
using the native DOM API (or jQuery of course).
