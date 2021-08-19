# Approved stacks

The goal of this document is to list which stacks have been tested and validated
internally so that you know what tools you can use without running into too much
trouble.

Of course it is possible to put any other tool on the table, but this would have
to be discussed and properly PoC'd. More on that later.

## Approved tools

The tools listed below are safe to use in most projects. Of course some client
requirements might change this but you will be notified if that is the case.

### Django

Django is the backbone of most things we do. There is lighter and in some way
better frameworks out there but to date none would justify giving up Django and
re-training the whole team on something else.

A few features that are paramount in Django:

-   **ORM** &mdash; This comes with no surprise that the ORM system is very
    important. Because you can introspect it easily, it enables automatic admin
    interface generation, automatic migrations, automatic serializers for the
    API, etc. Moreover it handles very complex queries and allows to leverage
    most of PostgreSQL's advanced features.
-   **Migrations** &mdash; Not only there is a migration system that allows to
    change the DB structure as you change the descriptive models but this
    migrations system handles cleanly the Git branching model and presents a
    great flexibility when it comes to doing "less-orthodox" changes.
-   **Auto admin interface** &mdash; The automatic admin interface generation is
    a huge time saver for many of our projects for which we didn't specifically
    sell a back-office but we still need to somehow inspect the data without
    going too deep into the SQL.

#### Django Rest Framework

DRF is an API generation tool. It is very flexible, very orthogonally designed.
In fact, it is practically considered as the standard way to create APIs in
Django. Of course it has a few quirks but overall we were never limited by it to
create the APIs we wanted.

Don't hesitate to use only parts of it for specific purposes. Typically:

-   Even if you're not doing a ViewSet you can still use a Serializer to
    validate JSON input from an untrusted source
-   The rate limiting system is fairly easy to use on its own, in case you want
    to rate limit authentication by example

#### Wagtail

A Django-based CMS. We use it as a traditional CMS or as a headless-ish CMS
depending on the project.

What we love:

-   StreamFields
-   More StreamFields
-   Fantastic management if images and thumbnails

#### Celery

Many projects require either period or background tasks. Celery is a perfect way
to run them in a scalable and observable way.

It's a bit frightening to start using it but it's actually very simple. All you
need is a RabbitMQ instance but the same applies: frightening but actually easy.

### Vue

There is a whole section on
{doc}`why we need a functional paradigm<functional-thinking>` in front-end web
and why Vue helps with this so there is not too many needs to explain this in
depth here.

Another excellent thing about Vue is its vue-loader. It allows to store in the
same file the HTML template, some (scoped) CSS and the JS that goes with it.
This makes it very easy to organize the code and to have automatic JS/CSS
bundles done by tools like Nuxt.

Why Vue and not another framework?

-   **React** &mdash; It's not actually reactive, there is many abstraction
    leaks and overall and different performance issues. This statement has been
    more or less true over the years and comparatively to Vue, but overall Vue
    served us well and there is no reason to switch to another monster.
-   **Svelte** &mdash; Svelte is very interesting because it allows to write
    many less lines of code and promises to be even lighter. The build tools are
    blazing fast. However there is many goodies found in Nuxt that you won't
    find in Svelte.
-   **Angular** &mdash; Angular had the genius of creating this concept of
    declarative templates. However it suffered from poor design and was complex
    to manage. It received complete overhauls and new versions but it was too
    late I was already on Vue (which is much, much simpler).

#### Nuxt

The best friend of Vue is Nuxt. As explained below, that's what you should use
to scaffold any Vue project. It solves under the hood _a lot_ of things that
you're probably not thinking about.

-   **Server-Side Rendering** &mdash; Essential for SEO, meta-tags reading and
    overall performance
-   **Auto-split of bundles** &mdash; Each page gets its own independent JS file
    which can be loaded individually. This allows to reduce the amount of code
    required to display the page and thus the amount of code that the browser
    has to parse to display the page, which is a **huge** selling point if you
    want to optimize Google's core web vitals.
-   **Automatic routing** &mdash; Routing is automatically generated from the
    file structure so you don't have to configure the router manually
-   **Good integration with Vue ecosystem** &mdash; Works with the store, many
    plugins exist to communicate with libraries from the ecosystem, etc.

### PostgreSQL

PostgreSQL is a libre database engine that is readily available on many cloud
providers and for good reasons: it has an incredible set of features.

-   **Indexable JSON fields** &mdash; Make NoSQL whenever you want
-   **PostGIS** &mdash; Very comprehensive extension to use geographical objects
-   **Full-text search** &mdash; Has a full text search ability on its own, no
    need to use an external engine like ElasticSearch for most operations
-   **Light-weight** &mbash; Uses just a few megabytes of RAM (if you don't
    count the data itself of course)

### Redis

It's a key/value store that keeps all its data in RAM. It is commonly used as a
cache, as a queue or as a store for not-so-important data.

### RabbitMQ

Queuing system, to use in conjunction with with Celery when appropriate. It's
actually quite simple to install and configure and will use very few resources.

### BERNARD

BERNARD is a home-grown framework to manage bot conversations. It allows to work
with Git and provides the abstraction layers that are required for our projects.

### NPM

In order to manage JS/CSS packages, this is definitely the package manager to
use.

### Pip

And in order to manage Python dependencies, Pip is the tool of choice.

```{note}
Pip _will be_ replaced by Poetry when we replace Felix, but now is not the time.
```

#### pip-tools

Some operations are a bit complicated with Pip alone, we use `pip-tools` to help
managing pinning versions and upgrading what we need.

## Approbation procedure

Any tool you want to use can be considered. Even if it's not in the pre-approved
list above or if it's in the deprecated list below. You just need to talk about
it with your manager, with reasonable arguments in order to establish if it can
be used for the project that you're working on.

Of course this only applies to major and structural tools. If you want to use a
tiny Django app that helps you minify HTML, this is not really a point of
debate. Just make sure to choose something that is not full of bugs, security
issues and poor design decisions. In doubt, ask for help.

In order to work with new tools, it needs to clear the following requirements:

-   It has to be deployable. If it's not deployable with our current
    infrastructure then the question of upgrading deployment scripts can be
    raised. However that's a significant cost, so it must be done for good
    reasons.
-   The overall cost must either be paid by the client either pay for itself.
    For example we pay a ViewFlow licence yearly for some projects because it
    costs 700€ (on average two days of work) and saved many days by providing a
    strong structure.
-   The same project must not require too much re-training of the team on its
    own. One major new tool in a new project is fine. Doing everything with
    completely different components would be quite dangerous.
-   It must be judged worthy by the Tech Lead both with a cold analysis and
    after a few days working on the project. If the tool is not performing as
    expected, it can be removed from the project, which takes time. So that's a
    risk that must be accepted when the project starts.

Those rules are a bit cold but they are by no means here to discourage
proactivity. If you got a tool that you think is worth it, let's talk about it
and roll it out. That's how Vue took over Angular in the early days, this can
happen again if something worthy appears on the scene (like, idk, Svelte).

## Deprecated libs

Those tools were heroes at a time, but heroes must die before they become the
villain.

### Moment

Moment brought features that are essential to date manipulation that the
standard JS library doesn't offer. However, it's just too fucking heavy. The
simple weight of it makes it an impossibility.

On top of that, it also features a very awkward API with mutable objects, that's
definitely the cause of a few bugs we had in the past. For more reasons, you can
check the
[You don't need Moment.js](https://github.com/you-dont-need/You-Dont-Need-Momentjs)
page.

As a good alternative (but definitely not a drop-in replacement at all) you can
have a look at [date-fns](https://date-fns.org/). Indeed, its functional
approach while still leaning on the native `Date` object makes it pretty
convenient to use. Specifically, it can be tree-shaked, so you don't need to
import code that you're not going to use.

### jQuery

To understand jQuery, you must understand that it was created at a time where
supporting Internet Explorer 5 was a thing. That's the kind of browser where
changing CSS could disable certain parts of the standard JS library. It was a
hell to work with it. But now, for most operations that jQuery allows you to do,
there is a very simple way to do it with the native API of browsers. So if you
want to manipulate DOM directly, you
[might not need jQuery](http://youmightnotneedjquery.com/).

However that's not the reason to ban jQuery for our projects. It's simply that
we don't use {doc}`the same paradigm <functional-thinking>` anymore. For that
reason it's not jQuery that is forbidden, but it's direct DOM manipulation that
is. Unless extreme cases (communicating with a legacy library, manipulating
things outside of Vue's scope, etc.), please use Vue's native pathways instead
of manipulating DOM.

### Vuetify

Vuetify looks like an amazing idea but in fact it's heavy, it's complex and it's
not fitting all that well with our designs. All projects that used it ended up
regretting it. So let's not use it anymore.

### Vue CLI

Vue CLI is a boilerplate generator for Vue.js which is basically a wrapper
around Webpack to let you access advanced Vue/Webpack features without having to
understand how to configure it.

While it's a great tool, it does not cover one specific aspect which is a
requirement on most projects: server-side rendering. As explained in the
{doc}`build-lifecycle` part, we need a server-side implementation as well as the
compiled JS code. In essence, you will not be able to deploy your Vue CLI
project because it's simply incompatible with our infrastructure.

The good news is that there is a simpler, better alternative: Nuxt. You can use
Nuxt for any Vue project and it will be much simpler and more efficient than Vue
CLI.

### Yarn

Since Yarn was released, NPM learned a lot and definitely caught up. There is no
need for an additional piece of software in the stack.

### Tailwind CSS

Tailwind has several issues:

-   It comes with its own build complexity
-   It's impossible to apply the documentation process
-   If the CSS file is far away from the HTML it might make sense, however in
    the context of Vue/Nuxt the CSS is definitely close to the HTML so this
    reduces the need for it
-   Previous attempts at using it proved to be too divisive and didn't meet a
    broad adoption

For those reasons, let's stay away from Tailwind.
