# Conditional Expressions
*Conditional expressions* or *Conditional statements* in Infiltration Engine,
refers to a lightweight expression syntax used to return values.
They function similar to how you would assign something to a variable
or return a value from a function. They are expressions that need to be evaluated.

For example, in Luau, you would assign something to a variable like:

```lua
local detectionSpeed = (Mission_Difficulty == 1) and 0.8 or 1
```

Using conditional expressions, you can achieve the same function:

```java
(Mission_Difficulty == 1) ? 0.8 : 1
```

## Syntax
Conditional expressions adopts a C-Style and Java syntax.

### Logical operators
 * `!` The *NOT* operator. Used to negate a boolean value. For example, `!true` evaluates to `false`.
 * `||` The  *OR* operator. Evaluates true if at least one condition is true.
 * `&&` The *AND* operator. Evaluates true if both conditions are true.
 * `==` The *equality* operator. Checks if two values are equal.

### Grouping
 * `()` Parentheses are used for grouping expressions and controlling the order of operations,
 just like in standard mathematics.

### Ternary Operator
 * `?` `:` The ternary operator (also called the conditional operator). It's a shorthand for an if-else statement:
 `condition ? value_if_true : value_if_false.`

### Strings
 * `""` or `''` Used to define strings (sequences of characters).

 * `{...}`Used inside strings for placeholders (often called string interpolation or formatting),
 where the content inside the braces is evaluated and inserted into the string.
 For example, `"Hello {name}!"`; `"Oh my god! You're {IsDead ? 'dead' : 'alive'}!"`.

### Mathematical operators
 * `+` Your addition operator.
 * `-` Your subtraction or negation operator.
 * `*` Your multiplication operator.
 * `/` Your division operator.

### Comparison operators
 * `>` Your *'more than'* operator.
 * `<` Your *'less than'* operator.
 * `>=` Your *'more than or equal to'* operator.
 * `<=` Your *'less than or equal to'* operator.

## Booleans
Your standard booleans. You know 'em. You love 'em.

 * `true`
 * `false`

## Whitespace sensitivity
Conditional expressions are not whitespace sensitive.
Meaning expressions such as `A == B` and `A==B` does the same thing.

## Context and scope
If your expression contains variables, then the engine's evaluator will evalute those variables
based on the current enviremount.

 * If the expression is run on the **server**, variables will reference the *global states*.
 * If the expression is run on the **client**, variables will reference the *replicated global states*
 and its  *local or client states.*