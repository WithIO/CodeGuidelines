# Version Control

We are using version control with the following goals:

-   Have several developers working on the same project
-   Mirror the testing workflow into the code management
-   Give meta-information about why and when code was written

## Workflow

All repositories must follow the Git Flow workflow in conjunction with our own
conventions.

The main idea of Git Flow is that there is a `develop` branch which is the
"currently brewing" version. It _should_ be stable at all times but might not be
in case of a mistake. From time to time, when we decide that the code is indeed
stable and that all the new features present there are allowed to be pushed to
production. In that case, a release is done and the code is merged into the
`master` branch, which should be the reflect of the production.

For reference, you can read:

-   The initial
    [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/) blog
    post
-   Install the [git-flow](https://github.com/nvie/gitflow/wiki/Installation)
    tool on your computer

When using the `git-flow` tool and in particular with `git flow init` we'll
always use the default values.

```{note}
The fastest way to initialize Git Flow is with the `-d` flag:

    git flow init -d

This will automatically setup your local repo with the default options.
```

### Develop

This branch should always be a working product. If there is anything in
`develop` that doesn't work properly, it's considered to be a bug. For example,
if there is a link in the footer that you can't click, it's a bug. If there is
some code that will be used later/was used before but is not used now, that's a
bug.

Another characteristic of a working product is that it should be deployable and
deployed. The configuration for that repository to be deployed should be done
from the first commit and be kept current as the project lives.

```{note}
As we produce websites, if they can't be deployed they are completely
worthless. If you don't deploy from the beginning you _will_ have surprises
when deploying and it could cost you several days or weeks of deploy on the
delivery of your project. It is however the job of the SRE team to help you
get your deployments going, so don't hesitate to get in touch with them.
```

### Features

There is little doubt that the branches you'll create the most are feature
branches. The goal is to produce a small, complete increment on top of the
working product present on `develop`.

When starting a project, you can do a first commit the boilerplate (most likely
found from our internal project templates), deploy it and then create a feature
branch to start working on your ticket.

#### Naming

There is a 1:1 equivalence between a feature branch and a ticket, which is
denoted by the following convention in naming feature branches:

```
feature/w42_short_name_for_ticket
```

Let's break this down:

-   `feature/` is the standard prefix for feature branches in Git Flow
-   `w` is a letter that is here for obscure name validation and legacy reasons.
    You can put any letter, just stay consistent within the project.
-   `short_name_for_ticket` is a name that you can decide upon which will
    describe your current ticket. Don't put anything too long. Please note that
    this name is expected to be lower-cased and words have to be separated by
    `_` (and **not** `-`).

```{note}
This naming scheme lies upon a lot of accumulated legacy. It might change in
the future but for now the transition is not deemed worthy.
```

#### Making increments

It can be very hard for some kinds of epics to be broken down into incremental
changes due to several factors like large inter-dependent features or long
funnels.

In those cases it is essential to plan in advance how you are going to approach
the problem:

-   Maybe there is some very technical bits behind the UX, in which case you
    might want to start by PoC'ing the feature in a mock project using a similar
    stack. This will help you understand how it will work, what are your
    requirements, in which order can you collect and communicate the
    information, etc. It's not uncommon to imagine that the whole flow will go
    in a given way but then to realize while coding that you forgot to ask some
    essential information to the user
-   Maybe you can create a branch for you epic that will serve as temporary
    `develop`. Let's take the example of a 10-step subscription flow. Let's say
    that the "main" ticket is #40 and for each step there is a more specific
    ticket #41, #42, etc. You can create a `feature/w40_subscription` alongside
    with a `feature/w41_subscription_step_1` and so forth. As long as you keep
    on merging features into #40 while also maintaining #40 up-to-date with
    `develop`, there shouldn't be a problem.
-   In all those cases, you need to make absolutely sure that there is things to
    test and to show to your project manager every day and that everything can
    be deployed. Without which it can be very easy to get yourself lost in
    intangible progress for a long time and start not understanding anymore what
    you are doing.

No matter what you do, you need to plan it in advance, possibly taking the
advice from other people, to be sure that allow yourself to test and try
rapidly.

#### In practice

In order to create a feature branch you can use Git Flow

    git flow feature start w42_some_feature

Or if you want to base yourself off of another feature

    git flow feature start w43_some_feature_part_1 w42_some_feature

Then Git Flow has automatic "feature finish" which will merge your feature branch 
into develop (locally), this is the simplest approach.

However an alternative to "feature finish" is:

1. Merge develop into your branch with
   `git fetch origin -p && git merge --no-ff --no-commit remotes/origin/develop`
2. Resolve conflicts if any. Don't forget to test that the code runs and that
   migrations pass properly (if Django).
3. Push your code to GitLab
4. Create a merge request
5. Have someone review the merge request
6. Merge the code from GitLab

### Bugfix/Hotfix

Those two cases are not handled by the deployment system. Both have the same
concept but:

-   Bug fixes are exactly like feature branches except they're named bug fixes
-   Hot fixes are based on `master` and can fix a bug in production without
    merging code from develop into `master`

If you want to do a bug fix, simply create a feature branch.

If you want to fix a bug in production quickly, typically you can create a
feature branch, fix the bug and then create a hotfix into which you'll
`cherry-pick` the commit(s) that fixed the bug in order to put them into
production.

### Release

In order to merge content from `develop` to `master`, you need to make a
release. This happens following the SemVer semantics, aka `X.Y.Z` with:

-   `X` is the major version number. Before the first release it's 0, when the
    project is pushed into production it becomes 1 and when another major
    project goes on this code base (huge new set of features by example) then
    you can increment it.
-   `Y` is the minor version number. You would typically increment it when you
    merged new features into this release. That happens mostly when we do a
    monthly release of a project.
-   `Z` is the patch number. If you only fixed bugs or did very minor tweaks,
    increment this. Typically when you find bugs in production right after a
    monthly deploy.

```{note}
In order to make a release, please make sure that your local repo is up-to-date

    git checkout develop
    git pull origin develop
    git checkout master
    git pull origin master
    git fetch origin -p

Then you can list the existing tags

    git tag | sort -V

Then start the release

    git flow release start 1.2.3

Do the changes that you need, if any, then complete the relase

    git flow release finish -m '1.2.3' > /dev/null

And finally push all

    git push origin develop:develop
    git push origin master:master
    git push origin --tags
```

## Commits

Imagine that there is a weird bug in the code and you identify that it comes
from a specific `if` which contains a very weird condition. Obviously the
condition was written for a reason but why?

When you write a commit message, you need to make sure that the person which
will be fixing this bug (most likely you) will have the ability to understand
what drove this code to be written:

-   Explain what you're trying to do in an atomic and descriptive way for the
    first line of the commit (around 50 characters, max 70)
-   Leave a blank line after that title
-   Give detailed explanations of what needs to be clarified, formatted in
    Markdown and wrapped at 72 characters
-   Finish with a reference to the ticket (usually `meta#42` for the ticket
    number 42, if the repo structure is the standard one)

A good commit message would be

```text
Send emails only to customers

According to business rules, emails should be sent to customers only
but they were sent to all.

meta#42
```

## What can be commited or not

Ideally, we want to make the projects as simple as possible to install and to
transfer. However, not everything should end up in Git.

-   If it's a secret then it has no place in Git. Or more precisely, if it's
    more secret than the source code. Because the source code we write is often
    a secret in itself.
-   If it's too heavy (more than a few Mo) then you might want to consider other
    options. Should it go to a S3 bucket by example?
-   Anything that is specific to an instance of the code should also be avoided.
    Typically, don't commit your `.env`, don't commit your IDE configuration,
    don't commit a DB dump, etc.

```{note}
What you should commit however is lock files from package managers:
`requirements.txt`, `package-lock.json` and so on **have to be** in Git.
```

## GitLab structure

We use Gitlab for Git management (at least for now). Here are the conventions
that we follow.

### Structure

The standard GitLab structure is:

```text
gitlab.com/with-madrid/{client}/{project}/{component}
```

Regardless of what the verbose name of each layer is going to be, the group/repo
slugs should match the names that you are going to configure for deployment.

```{note}
You'll notice that there is systematically a component layer, even if the
project only has one component. This is because it's just too much of a pain
to create another component if the repo wasn't structured properly initially.
You might think that this will never happen but it will actually happen sooner
than you think.
```

### Components

Typical component names, to be respected when appropriate, are:

-   `api` &mdash; A Django API for a SPA/SSR/PWA/mobile app or a headless
    Wagtail
-   `website` &mdash; A pure Wagtail website
-   `front` &mdash; A Nuxt front-end
-   `bot` &mdash; A BERNARD bot

### Multi-repo for one project

Although there is several repos for several components, they should in many
regards be considered as one single repo. This means by example that if you
create a branch or a pull request in one repo then it should always exist in the
other repos.

```{note}
This is a bit of a pain in the ass and maybe all should be better organized
within one single repo, however due to how deployment and development tools
work in general it is a bit safer to take this approach for now. It might
change in the future if it makes more sense.
```

To mitigate the management cost of having several repos for a single project,
several tools are available:

-   Using PyCharm (and friends) you can do some important operations
    simultaneously on all repos like committing, pushing or changing branch.
-   Using a tool like [mu-repo](https://fabioz.github.io/mu-repo/) you can
    automatically manage several repos at the same time from CLI

If you're using mu-repo you can simply replace `git` by `mu` in the examples
above. For example `mu feature start w42_some_feature`
