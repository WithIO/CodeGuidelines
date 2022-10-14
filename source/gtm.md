# GTM

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
instructions (which are kind of not nice) because this helps to prove the
ownership of the website on other Google tools. If the guidelines from Google
are not followed exactly, this breaks the authentication mechanism and it can
become annoying.

## Django

From a purely Django app, using something like GTM (or any of the
marketing/tracking tools that we use) is usually fairly easy. You just have to
include the code into the `base.html` of your project's template and then inject
the environment variable `GTM_ID` into
it. [Here](build-lifecycle.html#django-templates) you have a guide on how to
access an environment variable from a Django template.

## Nuxt

Implementing GTM in Nuxt is a bit more complex and requires some configuration
but it will also give us some flexibility to push custom events.

I’ll use GTM as the main example to go straight to the point, but everything
that is explained here can be used in the same way for Matomo. You’ll find code
examples for both GTM and Matomo whenever there’s a difference between both
implementations.

### Insert the GTM script in the HTML

The minimized GTM script should be inserted as a `<script>` tag in all the HTML
files of a web application so that we can use it in all the pages.

However, using Nuxt we can create an `app.html` file in the root directory of
the app to override the Nuxt default template. It’s possible to insert the GTM
script just once in this file in order to have the dataLayer available through
all the app.

```html
<!-- ~/app.html -->

<!DOCTYPE html>
<html {{ HTML_ATTRS }}>
<head {{ HEAD_ATTRS }}>
    {% if (GTM_ID) { %}
    <!-- Google Tag Manager -->
    <script>(function(w, d, s, l, i) {
        w[l] = w[l] || [];
        w[l].push({
            'gtm.start':
                new Date().getTime(), event: 'gtm.js'
        });
        var f = d.getElementsByTagName(s)[0],
            j = d.createElement(s), dl = l != 'dataLayer' ? '&l=' + l : '';
        j.async = true;
        j.src =
            'https://www.googletagmanager.com/gtm.js?id=' + i + dl;
        f.parentNode.insertBefore(j, f);
    })(window, document, 'script', 'dataLayer', '{{ GTM_ID }}');</script>
    <!-- End Google Tag Manager -->
    {% } %}

    {{ HEAD }}
</head>
<body {{ BODY_ATTRS }}>
{% if (GTM_ID) { %}
<!-- Google Tag Manager (noscript) -->
<noscript>
    <iframe src="https://www.googletagmanager.com/ns.html?id={{ GTM_ID }}"
            height="0" width="0"
            style="display:none;visibility:hidden"></iframe>
</noscript>
<!-- End Google Tag Manager (noscript) -->
{% } %}

{{ APP }}
</body>
</html>
```

<details>
<summary>Code example for Matomo</summary>

The main difference between Matomo and GTM is the script that has to be
inserted.

```html
<!-- ~/app.html -->

<!DOCTYPE html>
<html {{ HTML_ATTRS }}>
<head {{ HEAD_ATTRS }}>
    {% if (MATOMO_ID) { %}
    <!-- Matomo Tag Manager -->
    <script>
        var _mtm = window._mtm = window._mtm || [];
        _mtm.push({
            'mtm.startTime': (new Date().getTime()),
            'event': 'mtm.Start'
        });
        var d = document, g = d.createElement('script'),
            s = d.getElementsByTagName('script')[0];
        g.async = true;
        g.src = 'https://matomo.yibugo.com/js/container_{{ MATOMO_ID }}.js';
        s.parentNode.insertBefore(g, s);
    </script>
    <!-- End Matomo Tag Manager -->
    {% } %}

    {{ HEAD }}
</head>
<body {{ BODY_ATTRS }}>
{{ APP }}
</body>
</html>
```

</details>


It’s very important that the variables `HTML_ATTRS`, `HEAD_ATTRS`, `BODY_ATTRS`
and `APP` are always present in this file. The `GTM_ID` variable is configured
in `nuxt.config.js`.

For more information about the Nuxt `app.html`, visit the oficial
documentation: [https://nuxtjs.org/docs/concepts/views/#document-apphtml](https://nuxtjs.org/docs/concepts/views/#document-apphtml)

### Nuxt configuration

Since the `GTM_ID` comes from an environment variable, so we need to declare a
hook that inserts its value in the app template parameters. This way we can
access that variable through HTML templates such as the `app.html` file.

```javascript
// ~/nuxt.config.js

hooks: {
    /**
     * Copy the environment variables declared in envCopy to be able
     * to use them in templates.
     */
    "vue-renderer:ssr:templateParams"(templateParams)
    {
        const envCopy = ["GTM_ID"];

        for (const key of envCopy) {
            templateParams[key] = process.env[key] || "";
        }
    }
}
```

Then we also need to declare the GTM plugin in our app plugins:

```javascript
// ~/nuxt.config.js

plugins: [
    // ... other plugins ...
    "~/plugins/gtm",
]
```

### GTM plugin

In order to be able to access the GTM `dataLayer` in all our Vue components, a
good solution is to create a Nuxt plugin that handles all the event
registrations.

```typescript
// ~/plugins/gtm.ts

import { Plugin } from "@nuxt/types";

/**
 * Type declaration to access window.dataLayer through all the app.
 */
declare global {
    interface Window {
        dataLayer: Array<any> | undefined;
    }
}

/**
 * Type declaration to access $gtm as part of the Nuxt context.
 */
declare module "@nuxt/types" {
    interface Context {
        $gtm: Gtm;
    }
}

/**
 * Type declaration to access this.$gtm in every Vue component.
 */
declare module "vue/types/vue" {
    interface Vue {
        $gtm: Gtm;
    }
}

/**
 * All the events must have an "eventName" attribute. All the other attributes
 * must be strings, numbers or booleans (basically any type that can be
 * stringified)
 */
type GtmEvent = {
    eventName: string;
    [key: string]: string | number | boolean;
};

class Gtm {
    dl: Array<any> | undefined;

    /**
     * Get the dataLayer instance from window if it exists.
     *
     * The dataLayer is where all the events will be pushed and sent to GTM.
     * The GTM script from app.html should insert the variable dataLayer in the
     * window instance if a GTM_ID exists.
     */
    constructor() {
        if (process.client) {
            this.dl = window.dataLayer;
        }
    }

    /**
     * Register an event in the dataLayer.
     *
     * If GTM isn't enabled right now, simulate the registration
     * by logging the event in the console.
     *
     * @param event Event to register. It will be sent to GTM as it is so it
     *  should already have all the necessary data (at least an "event"
     *  attribute)
     */
    push(event: GtmEvent): void {
        if (this.dl) {
            this.dl.push(event);
        } else {
            // eslint-disable-next-line no-console
            console.log("GTM", event);
        }
    }
}

/**
 * GTM plugin declaration. It creates a Gtm instance that will be shared through
 * all the app as $gtm.
 *
 * @param context Nuxt context.
 * @param inject Method that injects and enables the $gtm plugin in this app.
 */
const gtm: Plugin = (context, inject) => {
    const g = new Gtm();
    inject("gtm", g);

    /**
     * Register a listener for the router that emits a GTM event everytime the
     * current route path changes.
     *
     * The event "nuxtRoute" includes basic data about the current page such as
     * the page title and the current route path.
     */
    function registerRouterListener() {
        context?.app?.router?.afterEach(to => {
            setTimeout(() => {
                g.push(
                    (to as any).gtm || {
                        routeName: to.name,
                        pageType: "PageView",
                        pageUrl: to.fullPath,
                        pageTitle: document.title || "",
                        event: "nuxtRoute",
                    }
                );
            }, 1000);
        });
    }

    if (process.client) {
        registerRouterListener();
    }
};

export default gtm;
```

```{note}
Yes it’s TypeScript, you better know how to use it :)

Jokes aside, just remove the type declarations if you need to use JavaScript
(remember to remove also the “as any” in the router listener).
```

The only difference between GTM and Matomo is the way it calls it’s `dataLayer`.
It’s called `_mtm` in this case and we store it in `mtm`.

<details>
<summary>Code example for Matomo (JS)</summary>

```javascript
// ~/plugins/mtm.js

class Matomo {
    mtm;

    /**
     * Get the mtm instance from window if it exists.
     *
     * "_mtm" works in the same way as the GTM dataLayer: it's where all the
     * events will be pushed and sent to Matomo.
     * The Matomo script from app.html should insert the variable _mtm in the
     * window instance if a MATOMO_ID exists.
     */
    constructor() {
        if (process.client) {
            this.mtm = window._mtm;
        }
    }

    /**
     * Register an event in Matomo.
     *
     * If Matomo isn't enable right now, simulate the registration
     * by logging the event in the console.
     *
     * @param event Event to register. It will be sent to Matomo as it is so it should already come
     *  with all the necessary data (at least and "event" attribute)
     */
    push(event) {
        if (this.mtm) {
            this.mtm.push(event);
        } else {
            // eslint-disable-next-line no-console
            console.log("Matomo", event);
        }
    }
}

/**
 * Matomo plugin declaration. It creates a Matomo instance that will be shared
 * through all the app as $mtm.
 *
 * @param context Nuxt context.
 * @param inject Method that injects and enables the $mtm plugin in this app.
 */
const mtm = (context, inject) => {
    const m = new Matomo();
    inject("mtm", m);

    /**
     * Register a listener for the router that emits a Matomo event everytime the
     * current route path changes.
     *
     * The event "nuxtRoute" includes basic data about the current page such as
     * the page title and the current route path.
     */
    function registerRouterListener() {
        context?.app?.router?.afterEach(to => {
            setTimeout(() => {
                m.push(
                    to.mtm || {
                        routeName: to.name,
                        pageType: "PageView",
                        pageUrl: to.fullPath,
                        pageTitle: document.title || "",
                        event: "nuxtRoute",
                    }
                );
            }, 1000);
        });
    }

    if (process.client) {
        registerRouterListener();
    }
};

export default mtm;
```

</details>

We can split the contents of this file in 3 sections:

- TypeScript declarations: we declare some variable names so that we can access
  them through all the app with more help from the IDE (and we prevent
  TypeScript from crying).
- The `Gtm` class: an instance from this class will handle whatever is necessary
  to actually use the GTM `dataLayer`. That includes retrieving the `dataLayer`
  reference from the `window` instance and pushing events into it when it’s
  possible.
- The plugin declaration: creates a single `Gtm` instance and makes it
  accessible as the `$gtm` plugin. There’s also an example on how to register a
  router listener in order to track every route path change. You can find more
  information about Nuxt plugins in the oficial
  documentation: [https://nuxtjs.org/docs/directory-structure/plugins/](https://nuxtjs.org/docs/directory-structure/plugins/)
  .

Since we are using GTM as a Nuxt plugin, we can now register an event inside of
any Vue component:

```typescript
/**
 * Register a GTM event whenever a user starts playing a video.
 *
 * @param videoUrl Url of the video
 */
function trackVideoPlay(videoUrl: string) {
    if (!videoUrl) return;

    this.$gtm.push({
        event: "video_started",
        video_url: videoUrl,
    });
}
```

It’s possible to add any additional information to the event, but the `event`
parameter is mandatory. That way GTM will be able to recognize this event and
register it correctly.

```{note}
You'll also realize that there is a `@nuxt-gtm` module which we don't use. The
reasons are the same: it is simply too annoying to give it runtime config. The
TFS implementation is simple enough on top of complying with Google's
requirements, we don't need to use that module.
```
