# Warnings

This section will explain where to get warnings and in which cases you need to
take care of them or in which case you can ignore them.

## Warning sources

There is different kinds of warnings, at different levels of the code. Mostly:

-   The IDE will give you a lot of warnings. Those will often be "soft" in the
    sense that it's the IDE guessing things. But they will often be right.
-   Linters. It's like the IDE but usually more related to decisions of the
    coding style or practices we specifically want to encourage/avoid.
-   There are also warnings given directly by the frameworks. Those are hard.
    It's usually that something is getting deprecated. The framework doesn't
    make mistakes.

Of course all tools might emit valid warnings on their own.

## What warnings can be ignored?

To make things simple, here is the rule that lets you know when you can ignore a
warning: you can **never** ignore a warning.

```{warning}
If a warning shows up in the code it is considered to be a bug. It
does not matter how late you are. If your code gets merged into develop with
warnings that pop, that's a bug.
```

## How to deal with warnings

There is two possible outcomes for a warning:

-   Most likely the warning is right and you need to take action to fix what
    you've been warned about. Especially when it's the framework warning you,
    but in many other cases as well.
-   The warning can also be wrong and then you can silence it. If possible, try
    to justify the silencing in the relevant docstring.
