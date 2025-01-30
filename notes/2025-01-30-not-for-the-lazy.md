---
title: "Lazy Evaluation in Nix: Where Your Conditionals Go to Die"
date: 2025-01-30
description: Exploring lazy evaluation in relative depth
wordcount: process-anyway
---

# Lazy Evaluation in Nix: Where Your Conditionals Go to Die

If you have spent time in traditional programming languages, then you have
probably relied on conditionals (`if-else`, `switch`, `case`) at least once in
your life. In Nix, as a grace of lazy evaluation, many of those construct become
less relevant---or outright unnecessary. This post dives into _why_ this is the
case, and hopes to save you from a few pitfalls that come with this.

## What is Lazy Evaluation?

I first need to explain what Lazy evaluation is. Not just within the context of
Nix, but in programming in general.

Lazy evaluation means that expressions are not evaluated until their values are
actually needed. This is in contrast to strict (or eager) evaluation, where
expressions are computed as soon as they are bound to a variable. In more
practical terms, lazy evaluation helps avoid unnecessary computations by
delaying the evaluation of expressions. It's a powerful technique for improving
performance and managing resources efficiently.

### Laziness in Haskell

```haskell
lazyNumbers :: [Int]
lazyNumbers = [1..]

firstFiveNumbers :: [Int]
firstFiveNumbers = take 5 lazyNumbers
```

In this example `lazyNumbers` is an infinite list. However, the values are not
computed all at once. The `take 5 lazyNumbers` expression only computes the
first 5 elements of the list when required. That is the most typical example of
lazy evaluation I can think of. Key point is that the numbers are only generated
when needed, instead of being computed upfront.

### Laziness in Python

With some friction, we can implement lazy iteration in Python.

```py
def lazy_numbers():
    num = 1
    while True:
        yield num
        num += 1

lazy_gen = lazy_numbers()
first_five_numbers = [next(lazy_gen) for _ in range(5)]
print(first_five_numbers)
```

In this example, `lazy_numbers()` is a generator that lazily yields numbers
starting from 1. Unlike a typical _list_, the numbers are not computed all at
once. The `next(lazy_gen)` call only computes the next number when needed. So,
when we request the first five numbers, only the first five numbers are
generated.

In Nix, laziness manifests in several ways:

- **Unused branches of an if-else are never evaluated.**
- **Function arguments are not evaluated unless explicitly used.**[^1]
- **Attribute sets can include self-referential definitions, leading to infinite
  recursion errors only when an attribute directly refers to itself. ** [^2]

## The Death of Conditionals (or at Least Their Diminished Role)

In strict languages, conditionals are usually used to prevent expensive
computations from running unnecessarily. But in Nix, the very nature of laziness
means that an expensive computation inside an unused branch never executes.

Example:

```nix
let
  expensive = builtins.trace "This should not print!" (throw "Error");
  value =
    if false
    then expensive
    else "Safe";
in
  value
```

In an eagerly evaluated language, this would result in an error because
`expensive` would be computed before `if` even runs. In Nix, however, the
`false` branch is never evaluated, so the program executes safely.

## Functions: Only Compute What is Needed

Since function arguments are evaluated lazily, unnecessary computations can be
avoided naturally.

```nix
let
  alwaysReturnsOne = x: 1;
in
alwaysReturnsOne (throw "This should never be evaluated")
```

Even though we pass an expression that would normally cause an error, it is
never evaluated since `x` is not used inside the function body.

## Self-Referencing Without Infinite Loops

laziness allows for powerful self-referential structures that would be
impossible in strict languages without explicit mechanisms like `fix`. [^3]
We'll talk about `fix` shortly.

```nix
let
  # rec is a special form in Nix used for defining recursive
  # attribute sets, allowing circular references to resolve
  # lazily without infinite loops. You will find out very
  # quickly, however, that it is often discouraged.
  infiniteRec = rec {
    a = b + 1;
    b = a - 1;
  };
in
 infiniteRec.a  # This evaluates without an infinite loop
```

Here, Nix resolves `a` and `b` lazily, allowing this circular dependency to work
without crashing.

### What is `fix`?

`fix` is a function used in some functional languages (such as Haskell) to
define recursive expressions without requiring explicit naming. It applies a
function to itself, allowing the expression to refer to itself.

```hs
fix f = f (fix f)
fact = fix (\rec n -> if n == 0 then 1 else n * rec (n - 1))
```

### Other Examples

To help give you an idea of what lazy evaluation can do for you, e.g. in your
NixOS configuration, I'd like to demonstrate laziness in action.

**Lazy Lists**

In Nix, you can define infinite data structures like lazy lists without causing
infinite loops:

```nix
let
  lazyList = {
    head = 1;
    tail = lazyList.tail; # this is an infinite recursion, if it evaluates...
  };
in
  lazyList.head
```

**Delayed Computation in Attribute Sets**

```nix
let
  config = rec {
    setting =
      if useAdvanced
      then builtins.throw "Too expensive!"
      else "default";
    useAdvanced = false;
  };
in
  # evaluates to "default", error is never thrown
  config.setting
```

## Conclusion

Laziness is powerful, but it can lead to surprises:

- Debugging is harder because errors might not surface until a deeply nested
  expression is finally evaluated. `--show-trace` is your friend most of the
  time.
- Performance tuning requires careful observation of when expressions are
  actually computed.
- Memory usage can balloon if large unevaluated thunks pile up, leading to
  unexpected memory pressure. Though, Nix's performance woes come from
  elsewhere.

A very good question would be _"why did you write this post?"_ Truth is, I want
to make it clear that Nix is _not_ one of your traditional languages. There also
seems to be a trend of new Nix/OS users failing to understand Nix _is_ a
programming language, and it is a functional one no less. I wanted to make it
very clear that some of the "issues" (such as dreadfully long error messages)
are an occupational hazard.

To conclude, laziness in Nix removes the need for many traditional control flow
constructs, albeit with its own set of caveats. Rather than guarding expensive
computations with explicit conditionals, you often don't need to worry at
all---unused expressions simply never evaluate. However, laziness introduces its
own challenges, especially when debugging or managing performance.

Next time you are working with Nix, remember that you are using a domain
specific language that is bound to have its own quirks. Regardless of said
quirks, Nix is a very powerful language that trivializes Infrastructure as Code,
but _only_ if you treat it as code.

[Statix]: https://github.com/oppiliappan/statix

[^1]: Static analysis tools, such as [Statix] will warn you when the function
    argument is unused. For example in the `alwaysReturnOne` function I've used
    as an example above, Statix would've warned you about the unused argument
    `x`.

[^2]: This is possible due to lazy evaluation resolving circular dependencies
    without causing crashes. However, an infinitely recursing attribute can
    exist as long as it's not evaluated.

[^3]: I'm very well aware that there is a `fix` function in nixpkgs lib. I
    mainly want to focus on core Nix language, so applications of `lib.fix` are
    omitted this time around. I'd like to talk about `fix` and recursion
    specifically in another post, another time. This is already long as it is.
