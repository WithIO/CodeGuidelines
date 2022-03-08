# BigQuery Exports

Some projects will require you to export statistics to BigQuery. In order to
outline a common strategy in exports as well as to do parts of the tedious work,
we use (and maintain) a micro-framework named
[Smolqwery](https://pypi.org/project/smolqwery/), which you must use in your
projects when asked to do BigQuery exports.

The documentation of Smolqwery should cover how to use it.

In terms of strategy, you will likely be asked to compute statistics _after_ the
project is released so you must think the data model with statistics in mind
from the first day in order to be able to make the exports that projects
managers and data scientists will imagine.

First and foremost this means that you must be able to know what _was_ the state
of the DB at a specific point in the past. Like "how many users were registered
the 2nd of June 2021?". This sounds trivial but for more advanced queries it
becomes complicated.

The simplest way to go is to record all changes as events. "On the 2nd of June
2021, someone created an account". It's very important that those events are
entirely anonymous, as per GDPR.

Not having such events will make things complicated. A few examples of what can
go wrong:

- If we prune users every 12 months (like we should) but the statistic is just
    computed on how many registered users are there in the DB then at some point
    the number of registered users will start decreasing and no one will
    understand why (or even realize) the statistics are wrong
- Let's say you let the user have simulations of their project. They can
    either tweak the parameters or turn the simulation into a contract. If they
    change the parameters over several days, you will eventually get weird
    results when you count your simulations, since they will shift between two
    exports.

All projects should implement an event log for all important metrics!
