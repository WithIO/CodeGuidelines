# Testing

Testing is a big part of what we do. Let's review here the recommended policy on
what the developer needs to test.

```{warning}
Spoiler alert: you need to write unit tests for some parts of the application.
See below. But be aware that it's important, especially as the business
criticality of our projects is ever increasing.
```

## Base concepts

> Testing is doubting

Says the general wisdom.

Well let's doubt a lot! There is nothing more sure that on significant projects
there is bugs left behind.

But why exactly should we test?

-   To make sure that the code works now
-   To make sure that you know what code to write. If you can imagine a test for
    your code (automated or manual) then you have a well-defined task. If not
    then you have no idea what you're doing until it's done... And it can take a
    long time depending on the task. As a general rule, always imagine what
    you're going to test in &mdash; at most &mdash; a few hours when you start
    coding. Also imagine that at the end of the day (real day, not metaphoric)
    you'll have to deploy and your project manager will want to test something.
-   To make sure that the code that worked yesterday still works today

In a sense, the test is the ultimate specification.

## Methods of testing

The testing at WITH is way too manual and we need to improve our know-how in
this domain. Nonetheless, let's go through what you can do.

### Manual testing

Turns out that testing front-end always ends up being a very complex task.
Beyond the trivial examples found in documentations, you end up with complex
components that display a lot of information that you somehow need to mock and
not only it takes a lot of time now but also it is _so easy_ to make it diverge
from reality that it renders the whole process fairly useless.

That's why we employ a lot of manual testing.

You will usually find the testing procedure in the ticket. It will help you
understand what is expected from this ticket and perform the test yourself.

Try to test those front-end components in several browsers. Typically if you
develop using Firefox, have a regular run of the feature in Chrome or
vice-versa. And when the feature is done, use Browser Stack to try it out in an
old annoying version of Safari. And of course be aware of your attention points
by checking the features you use in [Can I Use](https://caniuse.com/).

### Unit testing

Fortunately for us, a lot of business-critical parts are easy to unit test. If
you're writing non-trivial code on the server (that is something else that
wiring up Serializers with ViewSets), you must test it with unit tests. Django
comes already with a a lot of
[testing facilities](https://docs.djangoproject.com/en/3.2/topics/testing/), you
should make use of that.

To accelerate the tests, you might want to set those settings on your local
`postgresql.conf` file (beware that it could mean data loss, but in dev it
doesn't really matter):

```text
fsync = off
synchronous_commit = off
full_page_writes = off
```

Also it helps to run Django's tests using the `--keepdb` option, which, as the
name suggests, won't re-create the DB every time. Don't worry, the DB is still
cleaned every time as the data is inserted in a transaction that gets canceled
in the end.

### End-to-end testing

It is worthy to note that Django allows you to do end-to-end testing through the
use of Selenium. So far it has been complicate to orchestrate with Nuxt (or
similar) apps, but we should probably dig in that direction for the future.
