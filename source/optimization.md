# Optimization

Our clients love to have a look at
[PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/)
and tell us that the website is too slow.

And often, they're right. But PageSpeed Insight's advice is very generic and
poorly explained. So we need to get a high score and not follow their advice?
How exactly?

## Core Web Vitals

Well, specifically we need to have Core Web Vitals. Because that's what is
impacting the SEO. Many other things can be optimized and probably need to be
but those Web Vitals are not too poorly designed and will hint strongly at weak
points we might have.

What are they?

-   **Largest Contentful Paint** (LCP) &mdash; How long does it take to have the
    largest paint done, aka how fast the content above the fold is displayed. By
    example if you have a huge image loading on the first carousel of the page
    this might impact that metric very strongly. Recommended value: 2.5s or
    less.
-   **First Input Delay** (FID) &mdash; How long is the CPU so busy parsing your
    JavaScript before the user can actually use the page. Recommended value:
    100ms or less.
-   **Cumulative Layout Shift** (CLS) &mdash; How many images or pieces of
    content appeared after the page load and triggered layout re-computation
    (which is a fairly expensive operation). Recommended value: 0.1 or less.

Now that we've got the goal in mind, let's see the different things that we can
do to avoid performance issues.

## Front-end best practices

Those are guidelines to know what practices you can use in priority to have the
greatest impact on the website's performance.

### Optimize images

> This affects LCP

It's 2021 and it's the year of using
[WebP](https://developers.google.com/speed/webp). Most browsers support it, it's
more efficient than JPEG and PNG combined and also manages transparency.
Basically, it's perfect.

Now, **most** browsers support it. We still need to support older legacy
browsers like Safari.

The basic strategy is:

-   All images should be available in WebP
-   But should have a fallback as PNG

This is done by using the
[`<picture>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture)
tag with several sources instead of using `<img>`. It doesn't mean that you have
to be responsive but it's highly advised to be.

Using the `<picture>` tag is not possible when doing a CSS background, so please
refrain from using the `background-size: contain` technique. Instead you can use
the more modern
[`object-fit`](https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit)
property. Of course some browsers don't support `object-fit` so depending on
what is your compatibility target you can have a fallback that uses the
background technique and serves the PNG image but this must only be activated
when `object-fit` doesn't work.

It is also very important to note that users **are not** expected to upload
optimized or properly-sized images. They can upload whatever they damn want.
It's the job of the website to make the best out of what was uploaded,
including:

-   Resizing the image to a decent size
-   Converting it to WebP and PNG
-   Cropping it smartly (by example using Wagtail's focal point feature)

In that matter, I recommend you have a deep read of Wagtail's
[images documentation](https://docs.wagtail.io/en/v2.9.3/topics/images.html).

As a shortcut for certain use cases, there is
[image template tags](https://github.com/WithIO/django-wools#wagtail-images)
available in Wools. Don't use it blindly though.

### Minimize the amount of JS to parse

> This affects LCP and FID

By far the most CPU-intensive operation of displaying a page is parsing and
compiling the JS code. It's not even running it, its mere existence is enough to
clog the main thread.

What can you do about it?

-   Minimize the amount of dependencies you use. Always prefer write a small,
    specific bit of code rather than importing a huge do-it-all dependency that
    will weight a ton. Once in a while, you can
    [analyze your Webpack bundles](https://blog.saeloun.com/2020/08/04/how-to-investigate-your-build-size-in-webpack.html)
    to know if you've embedded something too big in your project. Don't wait for
    the end of the project to do it, it will be too late!
-   Produce different smaller chunks and serve them separately. The browser will
    have several small files to parse instead of a big one. This gives it the
    opportunity to handle some events in between instead of being blocked for a
    long time. If you're using Nuxt, this is done automatically.

### Define all image/object sizes

> This affects CLS

You need to specify the sizes of all the items present on your page so that the
browser doesn't need to load them to know their size.

This mostly applies to images. Always specify a `width`/`height` to image
elements, or at least specify the size in CSS. Otherwise the browser will have
to download the image in order to know what is the size of the file and then
compute how big this image is going to be on the page.

Every time this kind of computation happens, the browser needs to re-compute the
whole layout, and that's fairly heavy for the CPU.

### Cache content

> This affects LCP

If your website is, by example, powered by Wagtail, then it might be that with
the gazillion StreamFields you've had to put in there the generation time is not
completely optimal. Could be around 1s to generate the whole page by example.
This is a lot of time. Fortunately, since 100% or 99% of the page is the same
for two visitors, the easiest way to deal with that is just to cache the whole
page and serve the same thing from cache every time.

If you've got specific modifications to do, like display the user's name on the
corner of the page, this is often better done on the client-side using Nuxt. If
your website is not a headless Wagtail chances are that the content is 100%
static.

### Inlining CSS

> This affects LCP

The CSS from the first page is best inlined rather than loaded separately: you
need it to display the page no matter what.

If you're using Nuxt it's done automatically. If not you're probably going to
need to work a little bit.

### Bad ideas

Here are a few recommendations from PageSpeed insight that are probably
counter-productive and should be avoided. Most of the performance issue should
be resolved by the advise from above. Please avoid all PageSpeed advice until
you're sure that you have completely covered the points advised in this page.

#### Lazy-load images

PageSpeed says "Defer offscreen images" but it's easy to misunderstand it and
think "ok let's lazy-load all images".

Here is the thing: loading images is not that heavy. It's actually very easy for
the browser. The only impact it has is on the bandwidth of the user but if your
goal is to load those images anyways it doesn't change much.

What is heavy is preparing a frame for an image, noting down to load it later,
wait for a bunch of stuff to load and then load the image.

If you lazy-load something that is above the fold you are going to completely
kill the LCP metric of your page.

So, given the complexity of lazy-loading and the fact that you will most likely
just end up degrading performance, it is not recommended to lazy-load images at
all.

#### Enable text compression

Google will advise you to gzip your HTML code when serving it to the browser.
This is a particularly bad idea because with the current state of things you
need to choose:

-   You can encrypt things
-   Or you can compress things

But if you encrypt things that are compressed then you have a security issue. As
it happens, there is a high chance of having some kind of security token
embedded in the HTML code (like a CSRF token).

So, given the little added-benefit of compressing HTML output, it is not advised
to do it. At least not for pure Django projects.

## Back-end best practices

On the back-end, you need to be aware that your bottleneck is your database. To
parody, you can only write one thing at a time and you also can't read things
that are being written.

### Use bulk inserts/upserts

If you need to insert several rows at the same time, make sure to use Django's
[bulk_create](https://docs.djangoproject.com/en/3.2/ref/models/querysets/#bulk-create).

```{note}
You can't use it if your model uses table inheritance. So let's stay away from
table inheritance :)

Pro-tip: if you want to use inheritance to avoid repeating field names but you
don't actually want the data to be inherited, you can use `abstract = True` in
your parent model's `Meta`.
```

If you need to insert OR update if already present, then we're talking about
upserts. This is made possible in different flavors by
[`django-postgres-extra`](https://django-postgres-extra.readthedocs.io/en/master/conflict_handling.html).

As a rule of thumb, you can insert/upsert 1000 rows at a time. Above this number
the performance gains are negligible. But if you `bulk_create` 1000 rows the
performance will be about 100x superior to what you'd get by doing 1000 separate
`create()` calls. This is a very, very strong optimization.

### Avoid locking

If you know that you're going to have massive amounts of data, you'll need to
think the data model and the way your code works so that you can naturally
update the database with locking it as few as possible.

This is the condition to meet if you want your application to be working
concurrently on several processes and thus that it is able to scale it easily.
