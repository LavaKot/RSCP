# RSCP

**A scripting language as light as Python, shaped like Rust — implemented
from scratch in Rust.**

RSCP ("Rust-Compiled Scripting Platform", pronounced *risc-up*) keeps the
braces, `fn`/`let`/`var`, ranges and closures of Rust, but drops the
ceremony: no semicolons, no parentheses around conditions, no type
annotations. Under the hood it is still a bytecode compiler and a stack
virtual machine with zero external dependencies.

```rust
# The traditional first program.
println("Hello, RSCP!")

# FizzBuzz, the 2026.2.0.0 way — no ';' anywhere.
for i in 1..=30 {
    if i % 15 == 0      { println("FizzBuzz") }
    else if i % 3 == 0  { println("Fizz") }
    else if i % 5 == 0  { println("Buzz") }
    else                { println(i) }
}
```

```
$ rscp hello.rscp
Hello, RSCP!
```

Everything in this repository — the compiler **and** the programs it runs —
uses the `.rscp` extension. Compiler sources live in `src/`, RSCP programs
in `examples/` and `tests/cases/`.

---

## Quick start

Requirements: a Rust toolchain (1.75+; tested with 1.100).

```sh
./build.sh              # debug build + full test suite
./build.sh release      # optimized binary at target/release/rscp
```

Run a program:

```sh
rscp examples/fizzbuzz.rscp       # extension shortcut
rscp run examples/fizzbuzz.rscp   # explicit form
rscp repl                          # interactive session
rscp disasm examples/hello.rscp    # inspect the bytecode
rscp tokens file.rscp              # inspect the token stream
rscp ast file.rscp                 # inspect the parse tree
rscp update                        # self-update from GitHub (Windows)
```

### REPL

```
$ rscp repl
rscp 2026.5.5.0 — enter statements, Ctrl-D to exit.
rscp> let double = |x| x * 2
rscp> double(21)
42
rscp> for i in 0..3 { print(i) }
012
rscp> var s = 1 +
....> 2
rscp> s
3
```

Globals persist across lines, bare expressions are echoed, and a construct
that is still open (a dangling operator, an unclosed `{`) continues onto the
next line.

### Windows & editors

RSCP is portable: the whole implementation is plain Rust + `std` (no
Unix-only APIs, no external libraries), so the same source builds natively
on Windows, Linux and macOS. There is nothing to "convert" about `.rscp`
files — they are plain UTF-8 text, run by the `rscp` binary the same way
Python runs `.py`:

```
rscp hello.rscp        # Linux / macOS
rscp.exe hello.rscp    # Windows
```

Editor support ships in [`editors/`](editors/README.md), for every editor:

* **VS Code / VSCodium / Cursor** — a real extension, packaged and ready:
  `code --install-extension editors/vscode/rscp-2026.5.5.0.vsix`
  (highlighting, 16 snippets, brackets, auto-indent; see
  [`editors/vscode/README.md`](editors/vscode/README.md), на русском).
* **Vim / Neovim** — `editors/vim/` (syntax + detection, tested).
* **Sublime Text** — `editors/sublime/` (TextMate grammar).
* **Notepad++** — `editors/notepad++/rscp-udl.xml` (import as UDL).
* **Windows Explorer** — `editors/windows/assoc-rscp.bat` associates the
  extension (double-click to run, "Open with" to edit).
* **Anything else** — one-line fallback associations map `.rscp` to Rust
  highlighting; `.rscp` is plain text, so every editor on earth can open it.

Staying up to date: `rscp update` (since 2026.2.1.0) downloads the latest
release from GitHub and swaps the files in place — nothing to delete or
re-download by hand, and the VS Code extension is refreshed automatically
when a `code` / `codium` / `cursor` CLI is found. The repository is
private, so the first run needs a GitHub token (Classic PAT with the
`repo` scope) saved once:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.rscp" | Out-Null
"ghp_YOUR_TOKEN" | Set-Content "$env:USERPROFILE\.rscp\token"
```

Building `rscp.exe` on Windows (three commands, no Visual Studio needed):

```powershell
winget install Rustlang.Rustup     # or download rustup-init.exe from rustup.rs
cd rscp
cargo build --release              # -> target\release\rscp.exe
```

---

## Language tour

### The light style (2026.2.0.0)

Semicolons are **optional**: a newline after a complete expression ends the
statement (Go-style automatic semicolon insertion). Trailing commas in
multiline literals are welcome. Comments run from `#` to the end of the
line, Python style — `//` and `/* */` are no longer comment syntax, and
the compiler prints a migration hint when it meets them.

```rust
var total = 0
for i in 0..10 {                  # exclusive range: 0..9
    if i % 2 == 0 { continue }
    total += i
}
for i in 1..=5 { total += i }     # inclusive range: 1..5

while total > 5 { total -= 5 }    # no parentheses around conditions
loop {                            # the Rust infinite loop
    if total == 0 { break }
    total--
}
```

Functions come in two weights:

```rust
fn fib(n) -> n < 2 ? n : fib(n - 1) + fib(n - 2)   # arrow body: implicit return

fn fibIter(n) {                                    # block body: explicit return
    var a = 0
    var b = 1
    for _step in 0..n {
        let t = a + b
        a = b
        b = t
    }
    return a
}
```

Short closures (`|params| body`) return their expression implicitly —
the Rust style:

```rust
let double = |x| x * 2
let add = |a, b| a + b
let constant = || 42
let withBlock = |x| {              # a block body needs an explicit return
    var t = x + 1
    return t * 10
}
fn applyTwice(f, x) -> f(f(x))
println(applyTwice(|n| n * 3, 7))  # 63
```

Continuation rules are the same as in Go: a line that ends with an operator
or a comma continues; a line that ends with a complete value ends the
statement. `{` stays on the same line as the condition it belongs to:

```rust
var a = [                     # trailing commas are fine
    10,
    20,
]
var s = 1 +                   # '+' at the end: the next line continues
    2 +
    4
var grade = "F"
if total >= 100 {             # '{' on the condition's line
    grade = "A"
}
else if total >= 10 {         # 'else' may sit on its own line
    grade = "B"
}
```

Most of the 2026.1.0.0 syntax still parses — semicolons and C-style `for`
loops keep working, and the two styles mix freely in one file. Since
2026.5.2, though, parentheses around an `if`/`while` condition are a syntax
error (the compiler points at them and suggests the plain form). The
C-style loop is the only form that still wants its parentheses (and its
internal `;`); prefer ranges:

```rust
for (var i = 0; i < 10; i++) { ... }   # legacy, still works
for i in 0..10 { ... }                 # the 2026.2.0.0 way
```

### Variables: `let` vs `var`

`let` binds immutably (like Rust `let` / C++ `const`), `var` mutably. A
`let` always needs an initializer; `var x` alone is fine and declares `x`
as `null` (since 2026.5.5) — assign to it later.

```rust
let answer = 42                # cannot be reassigned
var count = 0                  # can
var later                      # null for now, assign later (2026.5.5)
count += 1                     # += -= *= /= %=
count++                        # ++ -- (statement forms)
```

At the top level, a `let`/`var`/`fn` name may be declared only once; inside
a scope, names can shadow outer ones:

```rust
var x = 1
{
    let x = 2                  # shadows the outer x
    println(x)                 # 2
}
println(x)                     # 1
```

Assigning to a `let` is a compile-time error for locals, and a runtime error
for globals:

```
error[prog.rscp:3:1]: cannot assign to immutable variable 'x' (declared with 'let')
```

Note that `let` fixes the *binding*, not the contents: `let a = [1]; a[0] = 5;`
is legal (the array is still mutable through itself).

### Values and types

RSCP is dynamically typed with seven user-visible types:

| Type      | Literals                    | Notes                                   |
|-----------|-----------------------------|-----------------------------------------|
| `int`     | `42`, `0xFF`, `1_000`       | 64-bit, checked overflow                |
| `float`   | `3.14`, `5.`, `.5`, `1e-3`  | 64-bit IEEE 754                         |
| `bool`    | `true`, `false`             | the only accepted condition type        |
| `string`  | `"hi"`, `'hi'`, `"""multi"""` | UTF-8; `f`/`r`/`b`/`u` prefixes; see below |
| `array`   | `[1, 2, [3]]`               | reference type, any mix of values       |
| `map`     | `{"a": 1, "b": [2]}`        | string keys, reference type             |
| `function`| `fn(x) { return x; }`, `\|x\| x` | closures; see below               |

`null` is the absence of a value; `nil` and `none` are synonyms
(since 2026.5.5). `type(v)` returns a value's type name.
Ints and floats mix freely in arithmetic (`1 + 0.5` is `1.5`); `int / int`
is integer division, C style (`7 / 2` is `3`, `-7 / 2` is `-3`).

### Control flow

Braces are **required** for `if`/`while`/`loop`/`for` bodies — no
dangling-else bugs — and conditions are written plain: `if x > 5 {`.
Parentheses around the whole condition are a syntax error since 2026.5.2
(parens that are part of a bigger expression, like `if (a + b) * c > 0 {`,
still parse).

```rust
if x < 10 { println("low") }
else if x < 100 { println("mid") }
else { println("high") }

while n > 0 { n-- }

loop { break }                            # infinite loop

for i in 0..10 { ... }                    # exclusive range
for i in 0..=9 { ... }                    # inclusive range
for v in [10, 20, 30] { println(v) }      # iterate array elements
for k in keys(mapVar) { println(k, mapVar[k]) }  # map keys, sorted
for var i in 0..3 { i = i * 10 }          # `var` makes the loop variable assignable
```

A range's end binds tightly: `for i in 0..n - 1` iterates `0..(n-1)`.
Ranges exist only as the iterable of a `for` loop — `let r = 0..5;` is a
compile error.

### Pattern matching: `match`

`match` is an **expression**: the value of the whole thing is the value of
the first arm that matches. Patterns are literals, alternations, integer
ranges, guards (`if`), and bindings that name the matched value. `_` or
`else` is the catch-all and must come last.

```rust
fn describe(n) -> match n {
    0 => "zero",
    1 | 2 => "one or two",       # alternation
    k if k < 0 => "negative",    # guard over the binding k
    3..=9 => "a digit",          # inclusive range (3..9 is exclusive)
    else => "many"               # catch-all: also spelled _
}

var size = match len(items) { 0 => "empty", 1..=5 => "small", _ => "big" }
```

An arm body is an expression, or a `{ }` block whose **last expression
statement is the arm's value** — handy for multi-step arms:

```rust
var label = match user {
    "admin" => "root",
    name => {
        let display = upper(name)
        "user: " + display
    }
}
```

Rules kept from Rust: a binding or catch-all only makes sense in the last
arm (earlier arms need an `if` guard, or the compiler rejects the match as
unreachable), and if nothing matches at runtime the match raises a
catchable `match: no arm matched the value` error. `break`/`continue`/`return`
inside an arm body do what they'd do in the enclosing loop or function.

### Modules: `import` and dot access

`import "file.rscp"` compiles and runs the module once (relative to the
importing file), then binds its top-level bindings — functions, constants,
anything — as an immutable map. Access members with dot syntax, which is
sugar for `["key"]` on any map:

```rust
import "math.rscp"             # binds the name from the file stem
println(math.double(21))       # 42
import "math.rscp" as m        # ...or pick your own name
println(m.golden)

var cfg = {"host": "localhost", "port": 8080}
println(cfg.port)              # dot reads...
cfg.port = 9090                # ...and writes; cfg["port"] still works
```

Diamond imports run the module body once (a cache keyed by path). Cycles
are a compile error. Exports are a **snapshot** of the module's top-level
bindings: pure functions and constants travel freely, and state works
through closures (shared upvalues) or arrays/maps exported by reference —
but a module function reaching for a module-level `var` by name after the
import is done sees the importer's globals, so keep mutable state inside
closures (`fn make_counter() { … }`) like in `examples/modules.rscp`.

### Errors: `try` / `catch` / `throw`

Runtime errors are values you can catch: division by zero, out-of-bounds
indexes, missing map keys, failed assertions, `panic()` — and your own
`throw`. The `catch` binds the error's message text (or stays unnamed):

```rust
fn parse_int(s) {
    try { return int(s) }
    catch e { return -1 }        # "int: cannot convert 's' ..."
}

try { risky(0) } catch e { println("failed:", e) }
try { throw "custom boom" } catch { println("caught!") }
```

Errors unwind cleanly through any number of function frames into the
nearest enclosing `try` (with upvalues closed on the way), the catch
binding is an ordinary local (closures can capture it), and `return`,
`break` and `continue` all leave `try` blocks correctly. A `try` whose
body completes normally costs one opcode — a handler push and pop.

Deliberately **not** catchable: stack overflow and internal errors —
catching those would risk an immediate second failure inside the handler.
Compile-time errors are of course still compile-time. An uncaught error
exits with code 70 and a stack trace, exactly as before.

### Functions and closures

```rust
fn add(a, b) -> a + b             # arrow body
fn makeCounter() {                # closures capture by reference
    var count = 0
    fn inc() { count++; return count }
    return inc
}

var tick = makeCounter()
tick(); tick()
println(tick())                   # 3 — count survived makeCounter's return
```

* Functions are first-class: `let f = add; f(1, 2)`.
* Anonymous functions are expressions: `fn(x) { return x * x; }`, or the
  short form `|x| x * x`.
* Arguments are evaluated left to right; arity mismatches are runtime errors.
* Names resolve at call time, so mutual recursion needs no forward declaration.
* Parameters are assignable; the function binding itself is immutable.

Closures can nest arbitrarily deep — an inner function can capture a variable
from any enclosing function (see `examples/closures.rscp`).

### Programs and `main()`

A file runs as a script: top-level statements execute in order. If a global
function `main` is defined (with no parameters), it is called after the top
level finishes — so `fn main() { … }` works as the familiar entry point
while quick scripts can just write statements.

```rust
println("top level runs first")
fn main() { println("then main()") }
```

### Operators

| Precedence (high → low) | Operators                                  |
|-------------------------|--------------------------------------------|
| 1                       | `()` call, `[]` index                      |
| 2                       | `**` (right-associative, like Python)      |
| 3                       | unary `! - ~`                              |
| 4                       | `* / %`                                    |
| 5                       | `+ -` (`+` also concatenates strings/arrays)|
| 6                       | `<< >>`                                    |
| 7                       | `&`                                        |
| 8                       | `^`                                        |
| 9                       | `\|`                                       |
| 10                      | `< <= > >=`                                |
| 11                      | `== !=`                                    |
| 12                      | `&&`                                       |
| 13                      | `\|\|`                                     |
| 14                      | `..`, `..=` (ranges, `for` iterables only)  |
| 15                      | `? :` (right-associative)                  |

Like Rust, the bitwise operators bind *tighter* than comparisons
(`a & mask == 0` means `(a & mask) == 0`) — the opposite of C's infamous
precedence trap. `&`, `|`, `^` work on two ints or two bools; `~` inverts
an int or a bool; shifts require the amount in `0..64`. Integer literals
come in four bases: `42`, `0x2A`, `0b101010`, `0o52` (with `_` separators).

Assignment (`=`, `+=`, `-=`, `*=`, `/=`, `%=`, `**=`, `&=`, `|=`, `^=`, `<<=`,
`>>=`, `++`, `--`) is a *statement*, not an expression — no `if (x = 0)`
accidents. Like Python, `**` binds tighter than unary minus (`-2 ** 2` is
`-4`) and stays an exact `int` while the exponent is a non-negative `int`
(overflow is an error); anything else promotes to `float`. `==` compares
numbers, strings, bools and `null` by value (`1 == 1.0` is `true`); arrays,
maps and functions compare by identity. `&&`/`||` short-circuit and require
bool operands; so do `if`/`while` conditions. The word forms `and`, `or`,
`not` (since 2026.5.2) are exact synonyms of `&&`, `||`, `!` at the same
precedence — note that `not` binds as tightly as `!`, so `not a == b`
means `(not a) == b`, like Rust and unlike Python. Integer overflow and division
by zero are runtime errors, not UB.

### Built-in functions

| Function | Behavior |
|----------|----------|
| `print(a, …)` / `println(a, …)` | print values space-separated, end the line (aliases since 2026.5.5) |
| `write(a, …)` | the same, without the newline |
| `len(v)` | string length (chars), array or map size |
| `str(v)` | value → string (`1.0` stays visibly `1.0`) |
| `int(v)` | float truncates toward zero; string parses (`int("42")`) |
| `float(v)` | int or string → float |
| `type(v)` | type name string |
| `abs` `min` `max` `sqrt` `pow` | numeric helpers (`pow` returns float, like C++) |
| `rand()` | pseudo-random float in `[0, 1)` |
| `clock()` | seconds since Unix epoch as float |
| `push(arr, v)` / `pop(arr)` | array stack operations |
| `keys(map)` | **sorted** array of keys (deterministic iteration) |
| `has(map, key)` | key-presence test |
| `assert(cond, msg?)` | runtime error if `cond` is false (catchable) |
| `panic(msg?)` | abort with a message (catchable with `try`) |
| `upper` `lower` `trim` | case and whitespace (`upper("héllo")` is `HÉLLO`) |
| `split(s, sep)` / `join(arr, sep)` | string ↔ array |
| `replace(s, from, to)` | replace all occurrences |
| `contains(s, sub)` / `contains(arr, v)` | substring / member test |
| `starts_with` / `ends_with` | prefix and suffix tests |
| `slice(x, a, b)` | substring or subarray; negative bounds, `b` exclusive |
| `find(s, sub)` | first char index of `sub`, or `-1` |
| `repeat(s, n)` | `repeat("ab", 3)` is `ababab` |
| `ord(c)` / `chr(i)` | character ↔ Unicode code point |

### Strings

Strings are UTF-8 and index by character: `s[0]` is a one-character string.
Concatenate with `+`, compare lexicographically with `<` and friends.

```rust
let s = "rscp" + "!"
println(s[0], len(s), s == "rscp!")    # r 5 true
```

Since 2026.5.3 strings come in Python-style literal forms: either quote
style, triple-quoted multiline bodies, and 1-2 prefix letters:

```rust
let a = 'single quotes'
let m = """line one
line two"""                         # a real newline inside
let win = r"C:\path\no\escape"   # raw: backslashes stay verbatim
let bs = b"hi"                      # bytes: [104, 105], an array of UTF-8 bytes
let u = u"plain"                    # u is a no-op (Python compatibility)
println("\x41\u{1F600}")          # A😀 — \xNN and \u{...} escapes
```

The prefixes are `f` (interpolation), `r` (raw), `b` (bytes — the value is
an array of UTF-8 byte values), `u` (no-op), and `f` combines with `r`:
`fr"raw {x} \n stays"`. Escapes: `\n \t \r \0 \a \b \f \v \e`,
`\xNN`, `\u{...}` (1-6 hex digits), `\\`, `\'`, `\"`.


**Slices** (2026.5.4) live directly in the index brackets, Python style —
any part optional, negative bounds count from the end, a negative step
walks backwards — and they cut arrays and strings alike:

```rust
let a = [0, 1, 2, 3, 4, 5]
println(a[1:3], a[::2], a[::-1], a[-1])   # [1, 2] [0, 2, 4] [5, 4, 3, 2, 1, 0] 5
println("abcdef"[1:4], "abcdef"[-4:-1])   # bcd cde
```

Plain indexing understands negatives too: `a[-1]` is the last element and
`a[-1] = 9` writes it (out of range is still an error). The `slice(x, a, b)`
builtin stays for the two-argument form.

A toolbox of builtins covers the everyday operations — `upper`, `lower`,
`trim`, `split`, `join`, `replace`, `contains` (works on arrays too),
`starts_with`, `ends_with`, `find`, `repeat`, `ord`, `chr`, and `slice`,
which also cuts arrays and understands negative, Python-style bounds:

```rust
println(upper("héllo"))                  # HÉLLO
println(split("a,b,c", ","))             # ["a", "b", "c"]
println(join(["a", "b"], "-"))           # a-b
println(replace("banana", "na", "NA"))   # baNANA
println(find("banana", "na"))            # 2 (first index, or -1)
println(slice("hello world", 0, 5))      # hello
println(slice([1, 2, 3, 4], -2, 99))     # [3, 4]
```

**f-strings** (Python-style interpolation) embed any expression in `{…}`;
`{{` and `}}` produce literal braces, and the holes nest — strings and even
other f-strings inside:

```rust
let name = "RSCP"
let n = 3
println(f"{name}: {n} squared is {n ** 2}")   # RSCP: 3 squared is 9
println(f"sum={1 + 2 * 3} nested={upper(f"{n}")}")  # sum=7 nested=3
```

The hole is parsed as a real expression at compile time, so mistakes inside
it are syntax errors with exact positions, and the pieces are joined at
runtime without building temporary arrays.

---

## Grammar

```ebnf
program        := statement* EOF ;

statement      := letStmt | fnStmt | ifStmt | whileStmt | loopStmt | forStmt
                | tryStmt | throwStmt | importStmt | returnStmt | breakStmt | continueStmt
                | block | assignment | incDec | exprStmt | ";" ;

letStmt        := ("let" | "var") IDENT "=" expression [";"] ;
fnStmt         := "fn" IDENT funcBody ;
funcBody       := "(" [ paramList ] ")" ( block | "->" expression ) ;
paramList      := IDENT { "," IDENT } [ "," ] ;   (* trailing comma ok *)

ifStmt         := "if" expression block
                  [ "else" ( ifStmt | block ) ] ;
whileStmt      := "while" expression block ;
loopStmt       := "loop" block ;
forStmt        := "for" ( forHead ")" block                       (* legacy *)
                            | ["let"|"var"] IDENT "in" expression block ) ;
forHead        := "(" ( forInit? ";" expression? ";" forStep?
                     | ["let"|"var"] IDENT "in" expression ) ;
forInit        := letStmt' | assignment' | exprStmt' ;   (* no trailing ';' *)
forStep        := assignment' | incDec' | exprStmt' ;
returnStmt     := "return" [ expression ] [";"] ;
breakStmt      := "break" [";"] ;
continueStmt   := "continue" [";"] ;
tryStmt        := "try" block "catch" [ IDENT ] block ;
importStmt     := "import" STRING [ "as" IDENT ] ;
throwStmt      := "throw" expression [";"] ;
block          := "{" ( statement | ";" )* "}" ;

assignment     := target ( "=" | "+=" | "-=" | "*=" | "/=" | "%=" ) expression [";"] ;
incDec         := target ( "++" | "--" ) [";"] ;
target         := IDENT | postfix "[" expression "]" ;
exprStmt       := expression [";"] ;

expression     := ternary ;
ternary        := range [ "?" expression ":" ternary ] ;
range          := logicOr [ ( ".." | "..=" ) logicOr ] ; (* for iterables only *)
logicOr        := logicAnd { ( "||" | "or" ) logicAnd } ;
logicAnd       := bitOr { ( "&&" | "and" ) bitOr } ;
bitOr          := bitXor { "|" bitXor } ;
bitXor         := bitAnd { "^" bitAnd } ;
bitAnd         := equality { "&" equality } ;
equality       := comparison { ( "==" | "!=" ) comparison } ;
comparison     := shift { ( "<" | "<=" | ">" | ">=" ) shift } ;
shift          := term { ( "<<" | ">>" ) term } ;
term           := factor { ( "+" | "-" ) factor } ;
factor         := unary { ( "*" | "/" | "%" ) unary } ;
unary          := ( "!" | "not" | "-" | "~" ) unary | power ;
power          := postfix [ "**" unary ] ;   (* right-assoc, tighter than unary *)
postfix        := primary { "(" [ arguments ] ")" | "[" expression "]" | "." IDENT } ;
arguments      := expression { "," expression } [ "," ] ;
primary        := INT | FLOAT | STRING | FSTRING | "true" | "false" | "null" | IDENT
                | "(" expression ")" | arrayLit | mapLit | "fn" funcBody
                | matchExpr | closure ;
FSTRING        := 'f"' { litChar | "{{" | "}}" | "{" expression "}" } '"' ;
matchExpr      := "match" expression "{" arm { ( "," | ";" )* arm } [ "," ] "}" ;
arm            := pattern { "|" pattern } [ "if" expression ] "=>"
                  ( expression | block ) ;
pattern        := INT [ ( ".." | "..=" ) INT ] | FLOAT | STRING
                | "true" | "false" | "null" | IDENT | "else" ;  (* "_" is IDENT *)
closure        := ( "|" paramList "|" | "||" ) ( expression | block ) ;
arrayLit       := "[" [ expression { "," expression } [ "," ] ] "]" ;
mapLit         := "{" [ expression ":" expression { "," … } [ "," ] ] "}" ;
```

A `;` is inserted automatically after a newline (or the end of input) when
the line ends with a value, `)`, `]`, `}`, `++`, `--`, `return`, `break` or
`continue` — and the next token cannot continue an expression (a `}`, `]`,
`)`, `,`, `:`, `?`, `else`, `->`, `=>`, `..` suppresses the insertion). A `{`
at statement position always starts a block; a map literal in that position
must be parenthesized: `var m = {"a": 1};` works, a bare `{"a": 1}` does not
(same rule as JavaScript).

---

## Errors and exit codes

Compile-time errors point at the exact character:

```
$ rscp bad.rscp
syntax error[bad.rscp:3:9]: expected ';', found 'let'
   3 | let x = 1
     |         ^
```

Runtime errors carry a stack trace (innermost frame first):

```
$ rscp err.rscp
runtime error[err.rscp:1]: division by zero
   1 | fn inner() { return 1 / 0; }
stack trace (innermost first):
  1. fn 'inner' at line 1
  2. fn 'outer' at line 2
  3. fn 'main' at line 3
```

| Exit code | Meaning (sysexits convention)      |
|-----------|-------------------------------------|
| 0         | success                            |
| 64        | bad command-line usage             |
| 65        | lexical / syntax / compile error   |
| 66        | input file could not be read       |
| 70        | runtime error                      |
| 141       | stdout closed early (SIGPIPE)      |

---

## Architecture

```
source (.rscp) ──► lexer ──► parser ──► compiler ──► bytecode ──► VM
                   tokens      AST        FnProto      Chunk      Value
                                                    (constants,
                                                     opcodes)
```

| Module            | Responsibility |
|-------------------|----------------|
| `src/token.rscp`  | token types, keywords |
| `src/lexer.rscp`  | source → tokens (positions, literals, comments, `;` insertion) |
| `src/ast.rscp`    | expression/statement tree |
| `src/parser.rscp` | recursive descent + precedence climbing |
| `src/errors.rscp` | unified error type, source-annotated rendering |
| `src/bytecode.rscp` | 54 opcodes, chunks, prototypes, disassembler |
| `src/compiler.rscp` | AST → bytecode; locals, upvalue capture, loop patching |
| `src/value.rscp`  | runtime values (`Rc`/`RefCell` reference types) |
| `src/vm.rscp`     | stack machine: frames, call stack, upvalue closing |
| `src/builtins.rscp` | 19 native functions |
| `src/main.rscp`   | CLI (`run`, `repl`, `disasm`, `tokens`, `ast`) |

Design highlights:

* **Bytecode, not tree-walking.** Programs compile once into a `Chunk` of
  54 one-byte opcodes (with `u8`/`u16` operands); the VM is a tight dispatch
  loop over call frames. `for i in 0..n` compiles to a counted loop — no
  array is built (same speed as the legacy C-style `for`), and `match`
  compiles to a jump chain — no allocations.
* **Proper closures.** Captured locals are shared *upvalue* cells that stay
  "open" (pointing into the stack) while the defining scope runs and close
  (copying the value out) when it returns — so two closures made in the same
  scope observe the same variable, exactly like C++ lambdas by reference.
* **Checked arithmetic.** Integer overflow, division and modulo by zero are
  clean runtime errors with a stack trace — not undefined behavior.
* **Reference types are explicit.** `let a = [1]; let b = a;` aliases; `==`
  on arrays/maps compares identity, on numbers/strings compares values.
* **No `unsafe`, no dependencies.** The whole implementation is safe Rust
  and `std` only; `cargo build` needs no network.

### Implementation limits

| Limit | Value |
|-------|-------|
| Locals per function | 255 |
| Parameters / arguments | 255 |
| Upvalues per function | 256 |
| Constants per function | 65 536 |
| Bytecode per function | 64 KiB |
| Call depth | 1024 frames |
| Expression nesting | 300 levels |

---

## Testing

```sh
cargo test
```

* **57 unit tests** across lexer (including the semicolon-insertion rules),
  parser (both syntax styles), compiler and VM (including closure
  semantics, mutability rules and error cases).
* **104 golden cases** in `tests/cases/`: each program's exact stdout is
  pinned in a `.out` file; error programs pin the exit code and a required
  stderr fragment in `.err` files. The suite spans every feature and every
  error class in this README, both the light and the legacy syntax.
* **10 showcase examples** are smoke-tested (`examples/`).
* The CLI surface itself is tested (exit codes, subcommands).

---

## RSCP vs Python vs Rust — where it sits

| | Python | Rust | RSCP |
|---|---|---|---|
| semicolons | none | required | optional (newline ends the statement) |
| blocks | indentation | braces | braces (required) |
| condition parens | no | no | no (a syntax error since 2026.5.2) |
| bindings | implicit | `let` / `let mut` | `let` / `var` |
| functions | `def f(x):` | `fn f(x) { }` | `fn f(x) { }` or `fn f(x) -> expr` |
| lambdas | `lambda x: x` | `\|x\| x` | `\|x\| x` |
| loops | `for i in range(n)` | `for i in 0..n` | `for i in 0..n` |
| infinite loop | `while True:` | `loop { }` | `loop { }` |
| slices | `a[1:3]`, `a[::-1]` | `&a[1..3]` | `a[1:3]`, `a[::-1]` |
| branching | `match` (3.10+) | `match` | `match` (expression, with guards and ranges) |
| bitwise | `\| & ^ << >>` | `\| & ^ ! << >>` | `\| & ^ ~ << >>` (Rust precedence) |
| types | dynamic | static, inferred | dynamic |
| memory | GC | ownership | refcounted `Rc` values |
| speed | interpreter | native code | bytecode VM (≈ C-style loop ≈ 180 ns/iteration) |

## Versioning

RSCP versions are four numbers: `YEAR.MAJOR.MINOR.PATCH`.

| Number | Counts what | Example |
|--------|-------------|---------|
| 1st | release year | `2026` |
| 2nd | major updates — new syntax, big features, breaking changes | `2` |
| 3rd | minor additions — a new builtin, snippets, docs polish | `0` |
| 4th | bug fixes and patches | `0` |

So the light-syntax release is `2026.2.0.0`: the second major update of
2026. The release that added `rscp update` is `2026.2.1.0` — a small,
non-breaking addition on top, still no bug fixes. A hotfix bumps only the
last number (`2026.2.1.1`), and the next year starts over at `2027.1.0.0`.

A tooling note: Cargo and npm manifests only accept three-number semver, so
`Cargo.toml` and the VS Code `package.json` carry the first three numbers
(`2026.5.5` in this release). The full four-number version lives in
`rscp version`, the REPL banner, release tags (`v2026.5.5.0`), release
file names and this README. Every release is published on GitHub as a tag
with the source zip, the Windows zip and the `.vsix` attached.

## Changelog

* **2026.5.5.0** — `print` and friends. `print(...)` is now the Python-style
  primary: it ends the line (`println` stays as an alias, and the no-newline
  form is the new `write`). `nil` and `none` are synonyms of `null`.
  `var x` without an initializer declares `x` as `null`; `let` still
  requires one. 61 unit tests, 104 golden cases.
* **2026.5.4.0** — slices and negative indexes, Python style.
  `a[start:end:step]` right in the index brackets (any part optional,
  negative bounds count from the end, a negative step walks backwards —
  CPython's rules) on arrays and strings; plain indexing understands
  negatives too: `a[-1]` is the last element, `a[-1] = 9` writes it.
  New `SliceGet` opcode. 59 unit tests, 102 golden cases.
* **2026.5.3.0** — Python-style string literals. Single-quoted `'...'`;
  triple-quoted multiline bodies; prefixes `r` (raw — backslashes stay
  verbatim), `b` (bytes — the value is an array of UTF-8 byte values),
  `u` (no-op compatibility prefix), combinable with `f`
  (`fr"raw {x} \n stays"`); new escapes `\xNN`, `\u{...}`, `\a \b \f \v \e`.
  58 unit tests, 100 golden cases.
* **2026.5.2.0** — word logic and plain conditions. `and`, `or`, `not` are
  exact word forms of `&&`, `||`, `!` (same precedence; `not` binds as
  tightly as `!`). Parentheses around `if`/`while` conditions are now a
  syntax error with a helpful message — write the condition plain:
  `if x > 5 {`. 58 unit tests, 98 golden cases.
* **2026.5.1.0** — Python-style comments. Line comments start with `#`;
  `//` and `/* */` are no longer comment syntax (division still uses `/`),
  and meeting one produces a clear migration hint pointing at `#`.
  TODO/FIXME/NOTE/HACK/XXX are highlighted inside comments by the VS Code,
  Sublime and Vim support. 57 unit tests, 96 golden cases.
* **2026.5.0.0** — modules and record-style access. `import "file.rscp"`
  [as name] compiles the file once (path-relative, diamond-cached, cycles
  rejected) and binds its top-level bindings as an immutable map; `m.key`
  dot access is sugar for `m["key"]` on any map, for reads and writes
  (`cfg.port = 9090`). Exports snapshot the module's globals; state works
  through closures and shared reference types (documented, with examples).
  58 unit tests, 92 golden cases, new `examples/modules.rscp`.
* **2026.4.0.0** — error handling: `try` / `catch` / `throw`. Runtime errors
  (division by zero, bad indexes, missing keys, failed asserts, `panic()`)
  are catchable values: `try { risky() } catch e { … }` binds the message,
  `catch { … }` stays unnamed, and `throw expr` raises your own. Errors
  unwind through any number of call frames (closing upvalues on the way),
  `return`/`break`/`continue` leave `try` blocks correctly, and stack
  overflow stays deliberately fatal. New opcodes `TryCatch`/`PopHandler`/
  `Throw` with a handler stack in the VM. 57 unit tests, 89 golden cases,
  new `examples/errors.rscp`.
* **2026.3.1.0** — strings, interpolation and `**`. f-strings
  (`f"n={n}, sq={n ** 2}"`) embed any expression, support `{{`/`}}` escapes
  and nest; the holes are parsed at compile time with exact positions. The
  `**` operator (and `**=`) is exact for `int ** int` with a non-negative
  exponent, promotes to float otherwise, is right-associative and binds
  tighter than unary minus — Python's rules. Thirteen new builtins:
  `upper lower trim split join replace contains starts_with ends_with
  slice find repeat ord chr` (`slice` also cuts arrays, with negative
  Python-style bounds; `contains` also searches arrays). 54 unit tests,
  86 golden cases, new `examples/strings.rscp`.
* **2026.3.0.0** — pattern matching and bitwise operations.
  `match` is a full expression: literal patterns, alternation (`1 | 2`),
  integer ranges (`3..=9`), `if` guards, bindings (`k if k < 0 => …`),
  block bodies (the last expression statement is the arm's value) and a
  `_`/`else` catch-all. Bitwise operators `& | ^ ~ << >>` with Rust
  precedence (tighter than comparisons), compound forms `&= |= ^= <<= >>=`,
  `& | ^` also work on two bools, and integer literals in four bases
  (`0x2A`, `0b101010`, `0o52`). New `panic(msg?)` builtin. Under the hood
  the compiler now tracks stack depth, so a `match` works in any operand
  position (`x += match … { … }`, as a call argument, inside loops with
  `break`/`continue` jumping out of arm bodies). 51 unit tests, 80 golden
  cases, new `examples/match.rscp`.
* **2026.2.1.1** — patch: `rscp update` is now Windows-only by design and
  fails fast on Linux/macOS instead of hunting for a PowerShell that some
  machines happen to have; golden-test expectations are CRLF-normalized
  and `.gitattributes` keeps the repo LF, so the test suite is green on
  Windows checkouts too (CI runs on Linux, Windows and macOS).
* **2026.2.1.0** — `rscp update`: self-update from GitHub releases. It
  downloads the latest Windows build, swaps `rscp.exe` in place (the
  running copy is renamed, then replaced; the leftover is cleaned on the
  next run) and refreshes the VS Code extension when a `code` / `codium` /
  `cursor` CLI is present. The repo is private, so the token is read from
  `%USERPROFILE%\.rscp\token` or `RSCP_GITHUB_TOKEN`. The golden suite no
  longer hardcodes the version string.
* **2026.2.0.0** — the light syntax: optional semicolons (Go-style
  insertion), `if`/`while` without parentheses, `for x in iter` with a
  fresh binding, ranges `a..b` / `a..=b`, `loop { }`, short closures
  `|x| expr`, arrow function bodies `fn f(x) -> expr`, trailing commas,
  `else` on its own line. Editor support for VS Code (.vsix), Vim, Sublime,
  Notepad++ and Windows association. All 2026.1.0.0 programs still run
  unchanged. *(Released under the old name "0.2.0" before the versioning
  scheme changed — same content.)*
* **2026.1.0.0** — initial release: lexer, parser, bytecode compiler, stack
  VM, closures, arrays/maps/strings, 59 golden cases, Windows build.
  *(Originally released as "0.1.0".)*

## License

Use it, fork it, teach with it — this project is provided as-is for study and
experimentation.
