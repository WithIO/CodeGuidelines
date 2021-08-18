# Code Formatting

This is probably the most sensitive topic out there. Everyone has a strong
feeling about indentation and overall rules for code formatting. This can even
break relationships.

```{eval-rst}
.. raw:: html
   :file: silicon-valley.html
```

As it is a matter of taste, we'll rely upon the following goals to define the
official style of WITH:

-   Must be as close to an industry standard as possible
-   Must be as deterministic as possible and easily automated
-   Must produce readable code
-   Must generate as little Git diff as possible
-   Must be easy to configure in development tools

```{warning}
If the code is not properly formatted following the rules below, this is
considered as a bug.
```

## Languages

Beyond the general philosophy, let's evaluate which tools we are going to use
for each language/tech that we use.

### Python

In Python, please follow the following rules:

-   Of course, the [PEP-20](https://www.python.org/dev/peps/pep-0020/) as a
    general philosophy
-   The [PEP-8](https://www.python.org/dev/peps/pep-0008/) for code formatting
    in general, including the use of `snake_case` for symbols and `CamelCase`
    for class names
-   You can format your code in any way you want as long as it matches the
    output of [Black](https://github.com/psf/black)
-   And finally imports are sorted using [isort](https://pycqa.github.io/isort/)
    (you'll thank me when you do your next merge)

In order to be compatible with Black, isort will require the following
`.isort.cfg` file at the root of the repo:

```ini
[settings]
multi_line_output=3
include_trailing_comma=True
force_grid_wrap=0
use_parentheses=True
line_length=88
```

It is conventional to have a `make format` command available in all projects
which triggers the re-formatting of the code. You can usually implement it by
adding the following to your `Makefile` (make sure that `PYTHON_BIN` is defined
properly in the Makefile):

```makefile
format: isort black
	exit 0

black:
	$(PYTHON_BIN) -m black --target-version py38 --exclude '/(\.git|\.hg|\.mypy_cache|\.nox|\.tox|\.venv|_build|buck-out|build|dist|node_modules|webpack_bundles)/' .

isort:
	$(PYTHON_BIN) -m isort xxx yyy zzz
```

With `xxx`, `yyy` and `zzz` the directories containing your code (by example
your Django apps).

```{note}
If you are adding a Django app in a project, you probably need to update the
Makefile in accordance.
```

```{note}
Black will automatically chunk lists, arguments, etc. if you put a traling
coma. If you feel like this list will be changed in the future, please add
a trailing coma in order to minimize the Git diff in the future. Example:

    x = [
        "a",
        "b",
        "c",
    ]

Here if you simmply wrote `"c"` and not `"c",` then Black would reformat it as
`["a", "b", "c"]`. However thanks to the trailing coma, Black knows it needs to
split that list.
```

### Web stack (JS, CSS, etc)

There is no equivalent to PEP-8 for most of the web techs, however, there is an
emerging tool on which we'll put your focus: [Prettier](https://prettier.io/).

The goal is to use it in all projects, as much as possible on all the files that
can be handled.

```{note}
As there is no SASS parser for Prettier, this means using SCSS instead of SASS
when we decide to use this CSS pre-processor.
```

The `.prettierrc` configuration file that you need to use is the following:

```json
{
    "trailingComma": "es5",
    "tabWidth": 4,
    "proseWrap": "always"
}
```

You'll notice that we have a `tabWidth` of 4 and that we're using space
indentation, just like in Python. The reason is simple: Black doesn't allow you
to configure it while Prettier does. Hence, Python indent style wins. I know. It
hurts. Please configure your IDE with 4 spaces indent and never change it. Thank
you.

Another thing is that we always use the `;` in JavaScript. I know you can omit
it, but sometimes it creates ambiguities and syntax errors. See it this way: if
you find it annoying to write code with semi-columns at the end of each line,
don't put the semicolons yourself but let Prettier do it for you. Fair enough?

In order to use Prettier, please use your favorite plugin for your favorite IDE.

```{note}
Prettier doesn't work so well on Django templates. If you're writing a Django
template, please inspire yourself from the Prettier syntax but deal as you want
with Django-specific template tags.
```

## .editorconfig

While this is not as comprehensive as the rest, just in case you should
configure your `.editorconfig` in all projects using the following template:

```ini
root = true

[*]
charset = utf-8
indent_style = space
indent_size = 4
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[Makefile]
indent_style = tab
```

Yes Makefiles get a special indentation style because otherwise it cases a
syntax error, but the rest can be with spaces.

## Case styles

This will be quick, but let's go over the main case styles and how we interpret
them. One important thing is that it should be easy to convert from one to the
other, and this is not just a hypothetical requirement: some frameworks and
tools do this conversion.

### `snake_case`

For most Python variables

-   Everything lowercase
-   Words seperated by underscore

Examples:

-   `hello`
-   `this_is_sparta`
-   `covid_19`

### `dash-snake-case`

This is for CSS. Almost the same as `snake_case` but for CSS variable names.

Examples:

-   `some-class`
-   `holly-molly-cow`
-   `-yolo`

### `CamelCase`

Class names in Python and most things in JS

-   Words in lower case
-   Separation by uppercase
-   First letter's case has a significance (usually if the first letter is
    uppercase it means that the symbol is a class)

Examples of class names:

-   `Covid19`
-   `Hello`
-   `WubbaLubbaDubDub`

Examples of JS variables

-   `someStuff`
-   `fooBar`

```{note}
In the `Covid19` example, even though `COVID` is an abberviation that should
be completely upper-cased, only the first letter has an upper case. This is
to facilitate conversion to `snake_case`. If you wrote `COVID19` then an
automatic converter would translate that into `c_o_v_i_d_19`, which is not
the most readable thing.
```

### `CONSTANT_CASE`

In case you want to declare a constant, aka some kind of setting of static value
that will be set once at the program's start and never change, you must use
`CONSTANT_CASE`.

-   All uppercase
-   Words are separated by an underscore

Examples:

-   `PI`
-   `PAGE_SIZE`
-   `COVID_19`

## Dealing with poorly formatted files

If a project's files are not properly formatted, please reformat it all in
accordance to this guideline:

-   Make the re-format in a commit whose only changes are the formatting changes
-   Yes this will lose some history, that's why everyone needs to make sure that
    their code is always properly formatted. Doing otherwise will cause
    disruption and readability issues for all the team. This is bad. Please
    format well your code.
