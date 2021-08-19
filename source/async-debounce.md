# The Async Debounce pattern

```{note}
This was initially an article published on
[dev.to](https://dev.to/xowap/introducing-the-async-debounce-pattern-36ff).
This will explain the slight change of tone between this page and the others.
```

The _callback hell_. It's the one thing dreaded more than anything by Javascript
developers. Especially when dealing with legacy APIs like jQuery or the Node
standard library. Fortunately, solutions were put in place. Frameworks like
Angular appeared which eased HTML rendering. Promises brought a standard and
easy way to handle asynchronous functions. Now `async`/`await` makes it easy to
write asynchronous code with non-linear paths.

However, now that this layer stabilizes into its final shape, it is a good idea
to start wondering how we're going to build higher-level patterns that we can
use for UI development.

Any typical UI basically breaks down into two things. A lot of information in
addition to inputs to navigate/filter/change this information. All of that
happens on the server side, the front-end simply being a view of that. Which
means that front-end and API have to communicate quite often to react to user
input. If you've been doing that long enough you know that:

-   It's not instant, you need to warn the user about the ongoing action
-   Users tend to be ~~stupid~~ impatient and click the buttons a gazillion
    times during loading
-   Sometimes errors occur and you always forget to catch them at some point,
    usually crashing the whole thing and leaving the UI in an undesirable state

There is of course a lot of other problems but I focus on these because they all
are related to one above-mentioned particularity in everyone's favorite
language. Wrapping your head around asynchronous code is fucking hard. Wrapping
your user's head around it is even harder.

## Expected flow

All right then let's not do it. Or rather, do it once and for all and then stick
to an easier mental schema.

Suppose that you're doing some instant-search-like UI. You type into an input
and the results appear live underneath. Put the edge cases away. What mental
model do you make of it?

1. A user event triggers a call (`__call__()`)
2. You check if the request is valid (`validate()`)
3. Then make sure that a loader is displayed to the user (`prepare()`)
4. At this point you can run the request (`run()`)
5. Depending on the outcome you either handle the results (`success()`) or the
   error (`failure()`)
6. Now that all is loaded you disable the loader (`cleanup()`)

And why would it be more complicated? Keep that model in mind and implement each
of the hooks then you're good to go. Thanks to Promises, whatever task that
`run()` does can be abstracted away like that. Especially since most of the time
it's a single API call through `axios` or another HTTP library which already
returns promises.

Now of course, what happens if the user clicks during the `run()`? What if you
want to wait before doing the first request? Well I thought about the possible
edge cases and came up with this diagram:

![Async Debounce Flow](https://thepracticaldev.s3.amazonaws.com/i/a7p23s1vluk5wn0cxj07.png)

Do you need to understand it all? Maybe, maybe not. All the arrows, connections
and hooks were thought carefully to be as orthogonal as possible and so it can
be pushed further if needs to be. If that's what you want to do then you
obviously need to understand it. If not, just follow the instructions, keep the
simplified model in mind and all will be fine!

## Code example

Of course, I didn't stop at the diagram. Code is all that matters right?

Introducing [wasync/debounce](https://github.com/WithIO/wasync)!

For the matter of this example we'll walk through some code inspired by the
[debounce demo](https://github.com/WithIO/wasync/blob/develop/demo/Debounce.vue).

We're doing a mock search. You type something, it goes into a mock function
which echoes the query after 1 second and you display the results. All of that
using a Vue component.

The template is pretty simple:

```html
<div class="debounce">
    <div>
        <input type="text" v-model="search" />
    </div>

    <ul>
        <li>Search = {{ search }}</li>
        <li>Result = {{ result }}</li>
        <li>Loading = {{ loading }}</li>
    </ul>
</div>
```

We rely on a few variables:

-   `search` is the search query text
-   `result` is the result of that query
-   `loading` is a flag indicating the current loading state

Now let's insert the Debounce into the component:

```javascript
import { ObjectDebounce } from "wasync";

export default {
    // ...

    watch: {
        search: new ObjectDebounce().func({
            // insert code here
        }),
    },
};
```

From now on we'll call the output of `new ObjectDebounce().func()` the
_debounced function_.

As you can see, the debounced function can directly be used to watch a Vue value
(in this case, the search text). Thanks to the Vue watching system, this value
will be passed as argument to the `search()` function whenever the `search`
value changes.

```javascript
            validate(search) {
                return {search};
            },
```

The arguments used to call the debounced function &mdash; in this case the
search value &mdash; are passed verbatim to the `validate()` hook. This hook
does two things:

1. **Validate the input**. If the input values are not good, then it needs to
   return a false-ish value.
2. **Generate run parameters**. The return value of `validate()` will be passed
   as argument to `run()`. If you are returning an object, make sure that it is
   a **copy** that does not risk to mutate in the during the run.

```javascript
            prepare() {
                this.loading = true;
            },
```

The `prepare()` hook is here to let you prepare the UI for loading. In this
case, just set the `loading` flag to `true`.

```javascript
            cleanup() {
                this.loading = false;
            },
```

On the other hand, when the function finishes running we want to disable the
loader and we just do that by setting `loading` to `false`.

```javascript
            run({search}) {
                return doTheSearch({search});
            },
```

That is the main dish. It's where we actually do the work. Here it's symbolized
by the `doTheSearch()` function, but you can do any async work you want to do.

-   If `run()` returns a `Promise` then it will be awaited.
-   The first and only parameter of `run()` is the return value of `validate()`.
-   If the debounced function is called while running, only the latest call will
    result in another `run()`, the other ones will be discarded.
-   All exceptions and promise rejection will be caught and will trigger the
    `failure()` hook

```javascript
            success(result) {
                this.result = result;
            },
```

The success receives the return/resolve value from `run()` as first and only
parameter. Then it's up to you to do something with it!

```javascript
            failure(error) {
                alert(error.message);
            },
```

Thing's don't always go as planned. If `run()` raises an exception or is
rejected then the exception will be passed as first and only parameter of
`failure()`.

### Recap

In the end, this is what our component looks like:

```html
<template>
    <div class="debounce">
        <div>
            <input type="text" v-model="search" />
        </div>

        <ul>
            <li>Search = {{ search }}</li>
            <li>Result = {{ result }}</li>
            <li>Loading = {{ loading }}</li>
        </ul>
    </div>
</template>

<script>
    import { ObjectDebounce } from "wasync";

    function doTheSearch({ search }) {
        return new Promise((resolve) => {
            setTimeout(() => resolve(`You searched "${search}"`), 1000);
        });
    }

    export default {
        data() {
            return {
                search: "",
                result: "",
                loading: false,
            };
        },

        watch: {
            search: new ObjectDebounce().func({
                validate(search) {
                    return { search };
                },
                prepare() {
                    this.loading = true;
                },
                cleanup() {
                    this.loading = false;
                },
                run({ search }) {
                    return doTheSearch({ search });
                },
                success(result) {
                    this.result = result;
                },
                failure(error) {
                    alert(error.message);
                },
            }),
        },
    };
</script>
```

While this looks trivial, it's actually battle-hardened code that will provide a
smooth experience to the user no matter what their action is!

Please note that you can test stand-alone Vue components thanks to
[vue-cli](https://cli.vuejs.org/guide/prototyping.html).

## Conclusion

Some very common problems linked to asynchronous resources and user interaction
can be solved by a pattern that is quite complex but that is fortunately
factorized into a generic library within the `wasync` package.

This is shown in action within a simple Vue component with pretty
straightforward code which is actually quite close to what you would use in
production.

It comes from the experience of several projects which was finally factorized
into a library. I'm eager to get everybody's feedback on this, other solutions
that have been used and if you think you can apply it to your needs!
