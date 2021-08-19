# Build Lifecycle

From the code that you write until the code that runs into the client's browser
there is many stages of compilation, packing, deployment, etc. It's important to
understand these steps and how the data can flow through them.

Because we want a deployment system that automatically provides the domain name
and the SSL certificate and copies the database and many other goodies that
happen under the hood, we need to follow a given set of rules.

## Important stages

There is no official list of stages for an app and this list is not exhaustive,
however those are the important parts of the life of our apps through the lens
if what is available to you and what you can do with it.

### Coding

When you code, it's usually happening on your machine. It's easy because you
have full control over it and no constraints. This means that it's very easy to
start writing code that won't work once onto the servers.

A few attention points and techniques:

-   Make sure to have configured properly the Django storages to use S3 for
    media storage. Don't use local media storage.
-   Use the Goku endpoint (or any other kind of tunnel like ngrok) in order to
    be able to test your app through HTTPS. If you have content policy or CORS
    errors, it's the time to work out a solution. If the tunnel is too slow, at
    least test once through it.
-   Make sure that all the files that your code requires can be committed and
    are committed (see the {doc}`version-control` section for more details on
    what can be committed)
-   Don't use environment variables outside safe locations (more on that later).
    In practice, it means **don't use** `process.env` in Vue code.

The code that you write must work in such a way that there is no need to change
(or create) a single file in your repository to make it work. No matter the
configuration, the context or the server this code must be able to run as-is on
all the target platforms.

### Building

The build time is when you transform your code into something that can be
executed by the target platform. This includes:

-   Transpiling JS/CSS code
-   Creating minified bundles of code for the client
-   Regrouping static assets into one directory
-   Compressing static assets

What you're building is simply another form of your code. If you build your code
twice it should give exactly the same output. Hence, you can understand that at
the time of build there is **no access to environment variables**. You simply
cannot depend on environment variables to build your code, just like your code
is not generated from environment variables.

```{note}
There is a slight exception to this in Django's world. Indeed, `manage.py` will
not accept to start of `SECRET_KEY` and `DATABASE_URL` are not set. Fortunately
you don't need to have the right values of those variables for `collectstatic`
to work properly. This is an example out of a `Dockerfile`:

    env DATABASE_URL='postgresql://dum:dum@localhost/dummy' SECRET_KEY='dummy' python manage.py collectstatic --no-input --clear

As you can see, the values here are dummy and don't need to be anything "real"
as they will be used by the build process.

On the other hand, please make sure that you don't create in your code a
build-time dependency to environment variables.
```

The output of this build step will be stored somewhere before going to the next
phase. For example if you're building a Felix project then the build artefacts
are sent to a Git repo under `with-madrid/deploy` while if you're building for
Kubernetes it will be sent to a private Docker repository.

### Deploying

The deployment phase can vary _a lot_ depending on what you're doing, but
basically it will take the build artifacts from the build phase and copy them to
the server while also registering the service in proper locations and starting
the whole thing.

This, again, it depends on if you're using Felix or Kubernetes or something
else, but it's the same underlying idea every time.

```{note}
On Felix deploys, the build and deploy phase are distinct but happen indeed
automatically one after the other. It's easy to recognize: the weird bash script
is the build phase and when it moves to Ansible it's the deploy phase.
```

### Run time

When the code starts running on the server, that's when it finally gets access
to environment variables. Hooray!

But wait. Didn't way say that we can't use environment variables from Vue code?
Ain't we fucked already?

Fortunately, no! There is easy solutions to the most common problems that we
face.

```{note}
Not all existing projects follow these guidelines, for many legacy reasons.
There is no point trying to reproduce past mistakes, please follow the patterns
below instead.
```

#### Finding the API

Ok so you've got an `API_URL` variable that gives you the base path to the API.
How do you get this to the client?

Let's say that your front-end is `https://front` and your API is `https://api`.
Suppose that you want to create an item on the API by doing a
`POST https://api/api/item`. What do you need to do that?

-   First you need to know the URL of the API, aka the content of `API_URL`. But
    but we said no environment variables.
-   Second you need to avoid getting your ass busted by CORS, because a POST
    from `https://front` to `https://api` ain't gonna fly.

The easiest solution to this is to use the magic of proxies 🪄

Here we're going to explore a Nuxt-specific solution. Typically, in your
`nuxt.config.js` file you can have something like that:

```javascript
module.exports = {
    plugins: ["~/plugins/axios"],

    modules: [["@nuxtjs/axios", { proxy: true }]],

    proxy: {
        "/api/": process.env.API_URL,
    },
};
```

```{note}
We're putting the `axios` plugin in this demo to outline the fact that there
is a `proxy` option that you need to set to true. However it's not strictly
required to use the `axios` module to make the proxy work (but save yourself
some time and use the `axios` module).
```

```{note}
The `proxy` section of this configuration makes use of environment variables.
This is one of the few authorized places to use them.
```

By doing so, we're solving both problems at the same time:

-   From your code you make a `POST /api/items`
-   Which results in a `POST https://front/api/items`
-   Which is proxied by the server and generates a `POST https://api/api/items`

No CORS issue, no environment variables at build time. Of course there many
[options](https://github.com/http-party/node-http-proxy#options) to the proxy
module that you can modulate to fit your needs but this is the basic idea.

#### Using GTM

Project managers are always eager to add a lot of JavaScript into our pages and
this generally starts with GTM. In a nutshell, GTM (or other tag managers like
Matomo Tag Manager) are systems which allow to add tracking pixels and other
analytical tools into the page without changing the code of the page itself.
It's basically some JS code that will load as soon as the page is displayed and
will do as instructed by the project managers from their management interface.

To sum up, it's a good practice to include a tag manager into the project
because it will increase the flexibility of the app to include different
tracking tools without making changes to the code.

Another item is that the code must be integrated exactly following Google's
instructions (which are kind of not nice) because this helps proving the
ownership of the website on other Google tools. If the guidelines from Google
are not followed exactly, this breaks the authentication mechanism and it can
become annoying.

##### Django

From a purely Django app, using something like GTM (or any of the
marketing/tracking tools that we use) is usually fairly easy. You just have to
include the code into the `base.html` of your project's template and then inject
the `GTM_ID` into it.

To do so:

1. Create a `GTM_ID` environment variable
2. Read this variable from `settings.py`, something like
   `GTM_ID = os.getenv('GTM_ID')`
3. Create a
   [template context processor](https://docs.djangoproject.com/en/3.2/ref/templates/api/#writing-your-own-context-processors)
   that will inject this value in all template renders

```{note}
It is much simpler to use a context processor than to manually inject the value
each time you call `render()` to create a custom template tag.
```

##### Wagtail

In some cases, users are going to expect more configurability over what they can
put in the HTML. In those cases, instead of reading the values from environment
variables it is best to let some option to the user to configure this and store
it into database.

You can for example create the `raw_html_head` and `raw_html_body` fields which
you let the admin change from the Promote tab of the root page and then in the
template you fetch those values from DB.

##### Nuxt

That's not the simplest thing to do. There is an example in the TFS project so
I'll make links from here.

1. Create a plugin that will manage the JS you want to include. By example the
   [GTM](https://gitlab.com/with-madrid/tfs/front/-/blob/37858c749525c75f40f6d0ca710b6254cf19be5c/plugins/gtm.ts)
   plugin from TFS declares the `dataLayer` variable and sends an event to it
   every time there is a new page displayed (because GTM doesn't understand
   HTML5 routing)
2. List that plugin into `nuxt.config.js`
3. Hook up to `vue-renderer:ssr:templateParams`
   [to inject](https://gitlab.com/with-madrid/tfs/front/-/blob/37858c749525c75f40f6d0ca710b6254cf19be5c/nuxt.config.js#L151)
   the parameters you need
4. Modify/create `app.html`
   [to include the snippets](https://gitlab.com/with-madrid/tfs/front/-/blob/37858c749525c75f40f6d0ca710b6254cf19be5c/app.html)
   provided by GTM and inject there the value received thanks to the
   `vue-renderer:ssr:templateParams` hook

```{note}
Maybe you noticed that we could have done the same thing using the `head`
section of `nuxt.config.js` but for some reason we're doing this complicated
maneuver. It's simple: the `head` is evaluated at build time and cannot take
environment variables into account. Sad but true.
```

```{note}
You'll also realize that there is a `@nuxt-gtm` module which we don't use. The
reasons are the same: it is simply too annoying to give it runtime config. The
TFS implementation is simple enough on top of complying with Google's
requirements, we don't need to use that module.
```

This is of course fairly artisanal and will have to be adapted to the specific
needs of your project, but that can serve as a blueprint.

#### Getting a token to the front-end

Very, very rarely you'll need to get a token or some kind of value from the Vue
code. If you reach this point it's probably that you've ignored other advices in
this guide.

Nuxt provides you with a way to safely get bits of data available in Vue code.
It's the
[runtime config](https://nuxtjs.org/docs/2.x/directory-structure/nuxt-config#runtimeconfig)
section of the configuration. As the name might suggest, this is configuration
that is available at runtime.

Imagine that we have a website with 2 CSS styles that were made for two brands
of the same company that have the same website. Let's say it's brands
`very-nice` and `super-great`. As they ask you to host both websites separately,
you've created an environment variable `BRAND=very-nice` or `BRAND=super-great`
depending on the instance.

In that case your nuxt configuration file would look like:

```javascript
module.exports = {
    publicRuntimeConfig: {
        brand: process.env.BRAND || "very-nice",
    },
};
```

```{note}
The `publicRuntimeConfig` and `privateRuntimeConfig` options are authorized
locations for environment variables, as they are specifically designed for that
purpose.
```

Doing so allows you to get this information from Nuxt code:

```html
<template>
    <h1 class="branded-title" :class="brandClass">{{ brandTitle }}</h1>
</template>

<style lang="less">
    /**
     * Very important brand title
     */
    .branded-title {
        font-size: 100px;

        /**
         * Very Nice's identity is blue bada dee bada doo
         */
        &.-very-nice {
            color: blue;
        }

        /**
         * Super Great sees a red door and wants it painted blaaack
         */
        &.-super-great {
            color: red;
        }
    }
</style>

<script>
    export default {
        computed: {
            /**
             * Generates the brand's title based on the configured brand from
             * runtime environment.
             *
             * @returns {string}
             */
            brandTitle() {
                return (
                    {
                        "very-nice": "Very Nice",
                        "super-great": "Super Great",
                    }[this.$config.brand] || "???"
                );
            },

            /**
             * Returns the CSS class modifier for this brand, see in the CSS
             * style how this affects the title.
             *
             * @returns {string}
             */
            brandClass() {
                return `-${this.$config.brand}`;
            },
        },
    };
</script>
```

What happens under the hood is that when you ask Nuxt to serve you the page it
will modify its internal `__NUXT__` object (look for it in the HTML) to contain
this value. This way when the JS on the client side starts running, it can get
the value from there and use it.

If instead of `this.$config.brand` you used `process.env.BRAND`, the value would
have been replaced at build time and hardcoded as-is in the minified code. This
would go against the goal of being able to deploy the same code in different
environments.

```{note}
This can only work with Nuxt in `universal` mode. But we use Nuxt specifically
for its `universal` mode and its ability to do SSR, so all is fine. If you want
to use Nuxt in another mode then you need to seriously question your choices as
this guide won't be able to help you.
```

If you look into TFS, there is also a
[Iubenda](https://gitlab.com/with-madrid/tfs/front/-/blob/37858c749525c75f40f6d0ca710b6254cf19be5c/plugins/iubenda.js)
plugin integrated that makes use of this technique to start itself.

### Server vs Client-side rendering

You'd think that once the code is running and your environment variables are
injected through the proper channels you'd be out of your misery. Haha. Lol.

The **core** feature of Nuxt and the main reason why we use it instead of, let's
say, vue-cli, is its ability to do Server Side Rendering. Maybe let's do a bit
of history at this point:

-   Initially it was simple. The server generates HTML, sends HTML to the
    browser, the browser displays the page, that's it.
-   Then it became pretty common to have JavaScript on the client side to alter
    details of the page (zoom on images, display details about a post, click on
    some stars, etc). This is the jQuery era.
-   Then those details became huge parts of the page, at which point the JS
    framework craze started. The idea was: render 100% of the content on the
    client side and communicate with the server through an API. If apps can do
    it why can't web apps do it? This is the SPA era.
-   That was fantastic but presented one main big problem: Google doesn't run
    SPAs (or at least did not at the time). Which means that your whole app was
    just a blank page for Google. This is when JS frameworks decided that
    instead of just sending an blank page and doing the rendering on the client
    they would do a first render on the server, send the HTML output and then
    keep on rendering on the client. This is the famous SSR that we're talking
    about here.

In theory SSR is the best of both worlds and in practice it is indeed a lot of
things that were complicated before. Using Vue components and splitting them by
page, having the whole HTML code + just the required CSS to boost up the first
paint, etc. These things are really important for performance and using Nuxt
makes them super easy to get (as you don't actually do anything to get them).

However this comes at a price, which is that you need to understand the
limitations of SSR. Specifically, on the server there is no DOM, no canvas, no
video, no audio, none of all that. You can render HTML but not attach events.
Let's see how to navigate in those waters.

#### DOM stuff

The good news about most of the DOM operations is that it's Vue's job to
manipulate the DOM. So all you have to do is to only rely on Vue APIs (either
through the `template` part of your `.vue` files either through the `render()`
function).

If you absolutely need to use native DOM functions (like `findElementById()`,
`addEventListener()`, etc) then think again because it is highly unlikely that
you actually need them. As a reminder, Vue covers
[event binding](https://vuejs.org/v2/guide/events.html),
[changing the style or class of elements](https://vuejs.org/v2/guide/class-and-style.html)
and other [input bindings](https://vuejs.org/v2/guide/forms.html).

If you still absolutely need to use them, you can create sections of the code
that will not execute if you're on the server:

```javascript
if (process.client) {
    console.log("this is only executed on the browser");
}
```

This is also true if you're invoking a component that uses some kind of canvas
or other things that Vue doesn't manage. In those cases you can do:

```html
<template>
    <div class="some-component">
        <h1>Hello</h1>

        <client-only>
            <component-that-uses-canvas />
        </client-only>
    </div>
</template>
```

#### Data loading

As explained in the introduction, one of the core features of Nuxt is that
content can rendered on the server side so that Google is able to read the page
(but also that the page displays faster).

This means that you **cannot** use `created()`, `mounted()` or any other Vue
hooks to make queries to the server. When the component comes alive it is
already too late to fetch data.

This is why you must trigger all data loading from the
[asyncData()](https://nuxtjs.org/docs/2.x/features/data-fetching#async-data)
hook that Nuxt provides.

All magic comes at a price, the `asyncData()` hook doesn't have access to `this`
because the component isn't created yet but you still have access to the whole
context (`$axios`, `store`, etc.). What you return from `asyncData()` will be
injected into the component's data and additionally you have the opportunity to
cancel the request if you get errors from the server (by example a 404 if the
URL is wrong).

```{note}
It also applies in reverse: `mounted()` won't be called on the server. This
means that if you rely on some operations to happen in `mounted()` in order to
transform the DOM before it is displayed it won't work properly (although it
will look like it worked when you display the page, after a short blink).
```

The ultimate check to see that everything is loaded correctly is to open the
page, display its HTML code (**not** from the inspector but by doing `CTRL + U`)
and look for all the information that you need to be there:

-   Menu entries
-   Footer entries
-   Meta tags (OG for Facebook, meta description, `<title>`, etc.)
-   Page content

If those items are not present inside the HTML code that comes straight out of
the server then you have a problem of data loading that you need to fix :)

## 12 factors

These rules are the [12 factors](https://12factor.net/), largely invented for
Heroku, but (mostly) relevant for us regardless of the infrastructure that we're
deploying into (Felix, Kubernetes, etc.).

Let's see how we implement those factors:

1. **Codebase** &mdash; All the code shall be in a set of Git repositories. It
   is immutable, and we can deploy it identical to many locations. This is
   really a core concept here: the code **cannot be changed** between
   deployments.
2. **Dependencies** &mdash; Dependencies must be explicitly managed by the
   proper tool. In the case of Python it's Pip, in the case of JS/CSS it's NPM.
   In no case should dependencies be managed through submodules or copy/pasta.
   Doing so would result in version conflicts, security issues, technical dept
   and generally into confusion. More on that in the
   {doc}`Dependencies Management <dependencies-management>` section.
3. **Config** &mdash; If the code can't be modified, the configuration has to
   come from somewhere. The somewhere is an old mechanism very easy to use with
   all deployment systems: environment variables. In local this manifests into a
   `.env` file at the root of your project (that you somehow read either through
   IDE/shell extensions either with some module in the app to go fetch the
   `.env`'s content) and on the servers it's up to the deployment system to
   inject the environment variables when needed.
4. **Backing services** &mdash; Not all can be deployed as 12 factors. For
   example in the case of a DB this is completely impossible as this would
   contradict rule number 6 below. Those services must be managed differently
   and be considered as "attached" to your app. To keep up with the DB example,
   there will be a database instance created by the hosting provider and we'll
   simply give to your app the reference to this database through environment
   variables.
5. **Build, release, run** &mdash; Build stages must be strictly separated. This
   is a by-product of previous rules and will be detailed further in this
   document.
6. **Processes** &mdash; If you build your app as a stateless process then you
   remove a lot of management problems associated to that process. This means
   that state-keeping between requests must go through appropriate channels: a
   database, a S3 bucket, a queue, etc. You cannot rely on disk files, shared
   memory or anything stored locally on the process's host, as it might get
   deleted as soon as the request is over.
7. **Port binding** &mdash; The 12 factors manifesto says to expose everything
   through port binding. Well that was a bit complicated to keep up with this in
   Felix but everything is exposed via UNIX socket binding, which is basically
   the same thing. It's the allegory of a pipe: there is a pipe that will
   receive requests and return responses to these requests. This is the only
   point of communication between the process and its environment.
8. **Concurrency** &mdash; One of the main reasons for rule 6 is that you need
   to be able to scale up your app easily. Being able to spin several process is
   key to that and thanks to this model you can easily go from 1 to 100 workers
   in a few seconds. The only bottleneck here is obviously the database but
   usually managed DB services have the ability to scale up the instance easily.
   Although this means that you need to write queries that can scale up (avoid
   locks and race conditions), which is an entire story on its own.
9. **Disposability** &mdash; Processes should start and stop quickly and
   gracefully. This way you can easily interchange processes if you want to
   change the underlying machines hosting the service by example.
10. **Dev/prod parity** &mdash; All environments must be as similar as possible
    to avoid any surprises, and in fact our deployment scripts for develop and
    production are exactly the same.
11. **Logs** &mdash; Logs are stored in a central location, indexed and can be
    searched. It's considered as an events stream and not as a collection of
    files.
12. **Admin processes** &mdash; All that is related to the management of the DB
    or various administrative tasks must run as a one-off task. In Django's
    world this is management commands. There is no `/_secret/do-cron-jobs` URLs
    that will trigger some cron jobs or other "background" tasks, because in
    terms of security that's a bit borderline and because it would mean to use
    the web worker to accomplish those tasks. Instead, administrative processes
    should be spun on a different machine (at least in prod) and run
    independently of the web process.
