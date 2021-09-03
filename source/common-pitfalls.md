# Common Pitfalls

The goal of this page is to list a few of the most common pitfalls and bad
patterns that can easily be avoided.

## Not using the lib's GET query encoding

It is quite common to see code like this:

```javascript
async function doSomething(foo) {
    const resp = await this.$axios.get(`/do-something/?foo=${foo}`);
}
```

Or worst:

```python
import requests

def do_payment(user_name, price):
    return requests.get(f"https://pay-api.com/?price={price}&user_name={user_name}")
```

What if the user's name is `HahaP0wnd&price=1`? The final URL you're going to
reach is going to be:

```
https://pay-api.com/?price=42&user_name=HahaP0wnd&price=1
```

And boom. Your user is going to be billed 1€ instead of 42€, you've lost 41€.

These kind of injections can happen in a lot of situations. As always with
security practices: if it can happen sometimes, you must protect always.

Fortunately, it's actually much more readable and convenient to do this in a
safe way than to do it the dangerous way. Indeed, you can just do this:

```javascript
async function doSomething(foo) {
    const resp = await this.$axios.get(`/do-something/`, { params: { foo } });
}
```

Or that:

```python
import requests

def do_payment(user_name, price):
    return requests.get(
        f"https://pay-api.com/",
        params={
            "user_name": user_name,
            "price": price,
        },
    )
```

## Filtering empty values

There is a common pattern we use, particularly with Django's ORM, it's to store
empty values as empty strings. However this can cause some mishaps during
filtering. Indeed, if you consider an empty value being the lack of value and an
empty filter being the lack of filter then it's easy to write this without
noticing:

```python
from x.models import Article

def get_matching_articles(q: str = ""):
    return Article.objects.filter(title__contains=q)
```

However if `q` is equal to `""` you're going to filter all articles whose
`title` is `""` while actually you wanted all the objects since `q` is empty.

A more correct query would be:

```python
from x.models import Article

def get_matching_articles(q: str = ""):
    query = Article.objects.all()

    if q:
        query = query.filter(title__contains=q)

    return query
```

Be very careful about this as the consequences of mis-filtering could be
dramatic in some situations (by example letting hundreds of private contractual
documents publicly available, ask the TFS team).

## String concatenation

It's very common to see people using the string concatenation operator to
concatenate strings together. And indeed, the name might suggest it's a good
idea to do so. _However_.

When you're creating a string, you're usually integrating into it some data
that is _not_ a string. Like an integer or a UUID. Try to do this, you'll be
up for a surprise:

```python
print("Printing: " + 42)
```

But suddenly when you're working with variables whose type is not always clear
it become less obvious than you're going to fuck things up:

```python
def print_something(x):
    print("Printing: " + x)
```

So what can you do about it? Convert everything to string before concatenating?
Well there is much simpler these days:

```python
def print_something(x):
    print(f"Printing: {x}")
```

This will make sure that `x` is converted into a string before being converted.

The same also applies to JavaScript:

```javascript
function printSomething(x) {
    console.log(`Printing: ${x}`)
}
```
