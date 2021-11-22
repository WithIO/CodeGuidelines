# Monthly Maintenance

Projects needs to be maintained monthly in order to not fall into pieces. The
goal is to make sure that the technical debt is not growing or even shrinks a
bit every month.

There is a usually monthly budget for maintenance. Check with the project
manager how

## Bugs

The first and most important thing to fix is pending bugs. But where do you find
them?

-   User reports. Some bugs will be reported or present in the backlog. The list
    of open tickets needs to be reviewed alongside the project manager to
    prioritize them and decide what needs to be fixed.
-   Another goal is to get 0 errors reported in Sentry. When you start the
    maintenance, for every single exception found in Sentry, you need to
    understand what is causing the bug, how impacting it is and then to convert
    that into a ticket with the project manager. After your maintenance, there
    should be zero errors still coming up in Sentry.

## Updates

We also need to make sure that all packages stay up-to-date. See the
{doc}`dependencies management<dependencies-management>` guide for how to do the
updates, but let's talk about strategy here:

-   Lots of dependencies will be updated very easily, especially on the Python
    side. Update as many of those as you can.
-   Other dependencies, especially on the JS side, will release a new breaking
    version every 6 month that will require days of work to upgrade. You need to
    figure which they are and estimate how long the update will take then to
    plan these updates with the project manager.

In order to do this, let's be strategic:

-   First, have a look at the main packages we use. Django, Vue, Webpack, etc.
    Look at the changelog, read about the new features, the breaking changes,
    etc.
-   Try to update them more or less one by one (be smart, some things depend on
    each other).
-   For what you notice is complicated to make work, then estimate what are the
    blocking points then estimate how long you need to resolve it.

It is very important to keep frameworks and dependencies up-to-date. It might
have to be sold to the client if it takes too much time, but we need at least to
be aware of what is going on and what we need to do.

## Performance

All projects should have performance reporting enabled, in order to be able to
execute the following procedure. If the performance monitoring is not enabled,
please enable it so that you are able to work on it at the next occurrence of
the monthly maintenance.

### Absolute values

We need to make sure that the website runs smoothly for all users. It means that
95% of all HTTP requests to a specific endpoint should execute within 200ms.
That's the "P95" column in the Sentry performance monitoring page.

If you see endpoints that have a P95 over 200ms, it means that they need to be
optimized. To do so, you need to dig a little bit into what this endpoint does.
Then, it works a bit like the package updates:

-   Either you see a quick win and you fix it immediately
-   Either it's going to take too much time and you plan it with your project
    manager

```{note}
Be careful, Sentry mixes up Celery tasks and HTTP requests. When you're looking
be sure to ignore Celery tasks, which are intended for everything that cannot
be cut down to 200ms.
```

### Trends

For all the top requests of the page project, you need to have a look at their
individual history and see if the execution time is rising. An increasing
execution time can be the sign of an upcoming failure, by example with growing
amounts of data.

If something looks suspicious, you can start digging into the reason why the
value is growing and then act accordingly as explained above.

### Resolution

Overall, there will be a few common ways to optimize your website:

-   Optimizing the SQL queries and the use of the SQL engine in general (see the
    {doc}`optimization guide<optimization>`)
-   Make use of caching for pseudo-static content (Wagtail pages render, for
    example)
-   Move long-running endpoints to asynchronous tasks using Celery
-   Use a Python profiler to figure what is taking time and could be accelerated

As explained above, if the resolution is simple then fix it, otherwise let's
plan it in advance.

## Documentation

You can always use this occasion to write documentation on missing parts:

-   Global features explanations, sequence diagrams, etc
-   Installation procedure, updated with newer requirements
-   Fixing Markdown bugs

This is just suggestions. Make sure that the project is in a state that you
would have wanted to see when you jumped on it at the beginning of the day!
