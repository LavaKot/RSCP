# RSCP

**A scripting language as light as Python, shaped like Rust — implemented
from scratch in Rust.**

RSCP ("Rust-Compiled Scripting Platform", pronounced *risc-up*) keeps the
braces, `fn`/`let`/`var`, ranges and closures of Rust, but drops the
ceremony: no semicolons, no parentheses around conditions, no type
annotations. Under the hood it is still a bytecode compiler and a stack
virtual machine with zero external dependencies.

```rust
// The traditional first program.
println("Hello, RSCP!")

// FizzBuzz, the 2026.2.0.0 way — no ';' anywhere.
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
rscp 2026.2.1.0 — enter statements, Ctrl-D to exit.
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
  `code --install-extension editors/vscode/rscp-2026.2.1.0.vsix`
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
multiline literals are welcome.

```rust
var total = 0
for i in 0..10 {                  // exclusive range: 0..9
    if i % 2 == 0 { continue }
    total += i
}
for i in 1..=5 { total += i }     // inclusive range: 1..5

while total > 5 { total -= 5 }    // no parentheses around conditions
loop {                            // the Rust infinite loop
    if total == 0 { break }
    total--
}
```

Functions come in two weights:

```rust
fn fib(n) -> n < 2 ? n : fib(n - 1) + fib(n - 2)   // arrow body: implicit return

fn fibIter(n) {                                    // block body: explicit return
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
let withBlock = |x| {              // a block body needs an explicit return
    var t = x + 1
    return t * 10
}
fn applyTwice(f, x) -> f(f(x))
println(applyTwice(|n| n * 3, 7))  // 63
```

Continuation rules are the same as in Go: a line that ends with an operator
or a comma continues; a line that ends with a complete value ends the
statement. `{` stays on the same line as the condition it belongs to:

```rust
var a = [                     // trailing commas are fine
    10,
    20,
]
var s = 1 +                   // '+' at the end: the next line continues
    2 +
    4
var grade = "F"
if total >= 100 {             // '{' on the condition's line
    grade = "A"
}
else if total >= 10 {         // 'else' may sit on its own line
    grade = "B"
}
```

The whole 2026.1.0.0 syntax still parses — semicolons, parentheses around
conditions and C-style `for` loops keep working, and the two styles mix
freely in one file. The C-style loop is the only form that still wants its
parentheses (and its internal `;`); prefer ranges:

```rust
for (var i = 0; i < 10; i++) { ... }   // legacy, still works
for i in 0..10 { ... }                 // the 2026.2.0.0 way
```

### Variables: `let` vs `var`

`let` binds immutably (like Rust `let` / C++ `const`), `var` mutably. Every
variable must be initialized — there are no uninitialized reads in RSCP.

```rust
let answer = 42                // cannot be reassigned
var count = 0                  // can
count += 1                     // += -= *= /= %=
count++                        // ++ -- (statement forms)
```

At the top level, a `let`/`var`/`fn` name may be declared only once; inside
a scope, names can shadow outer ones:

```rust
var x = 1
{
    let x = 2                  // shadows the outer x
    println(x)                 // 2
}
println(x)                     // 1
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
| `string`  | `"hi\n"`                    | UTF-8, escapes `\n \t \r \0 \\ \" \'`   |
| `array`   | `[1, 2, [3]]`               | reference type, any mix of values       |
| `map`     | `{"a": 1, "b": [2]}`        | string keys, reference type             |
| `function`| `fn(x) { return x; }`, `\|x\| x` | closures; see below               |

`null` is the absence of a value. `type(v)` returns a value's type name.
Ints and floats mix freely in arithmetic (`1 + 0.5` is `1.5`); `int / int`
is integer division, C style (`7 / 2` is `3`, `-7 / 2` is `-3`).

### Control flow

Braces are **required** for `if`/`while`/`loop`/`for` bodies — no
dangling-else bugs — but parentheses around conditions are not.

```rust
if x < 10 { println("low") }
else if x < 100 { println("mid") }
else { println("high") }

while n > 0 { n-- }

loop { break }                            // infinite loop

for i in 0..10 { ... }                    // exclusive range
for i in 0..=9 { ... }                    // inclusive range
for v in [10, 20, 30] { println(v) }      // iterate array elements
for k in keys(mapVar) { println(k, mapVar[k]) }  // map keys, sorted
for var i in 0..3 { i = i * 10 }          // `var` makes the loop variable assignable
```

A range's end binds tightly: `for i in 0..n - 1` iterates `0..(n-1)`.
Ranges exist only as the iterable of a `for` loop — `let r = 0..5;` is a
compile error.

### Functions and closures

```rust
fn add(a, b) -> a + b             // arrow body
fn makeCounter() {                // closures capture by reference
    var count = 0
    fn inc() { count++; return count }
    return inc
}

var tick = makeCounter()
tick(); tick()
println(tick())                   // 3 — count survived makeCounter's return
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
| 2                       | unary `! -`                                |
| 3                       | `* / %`                                    |
| 4                       | `+ -` (`+` also concatenates strings/arrays)|
| 5                       | `< <= > >=`                                |
| 6                       | `== !=`                                    |
| 7                       | `&&`                                       |
| 8                       | `\|\|`                                     |
| 9                       | `..`, `..=` (ranges, `for` iterables only)  |
| 10                      | `? :` (right-associative)                  |

Assignment (`=`, `+=`, `-=`, `*=`, `/=`, `%=`, `++`, `--`) is a *statement*,
not an expression — no `if (x = 0)` accidents. `==` compares numbers,
strings, bools and `null` by value (`1 == 1.0` is `true`); arrays, maps and
functions compare by identity. `&&`/`||` short-circuit and require bool
operands; so do `if`/`while` conditions. Integer overflow and division by
zero are runtime errors, not UB.

### Built-in functions

| Function | Behavior |
|----------|----------|
| `print(a, …)` / `println(a, …)` | print values space-separated (println adds `\n`) |
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
| `assert(cond, msg?)` | runtime error if `cond` is false |

### Strings

Strings are UTF-8 and index by character: `s[0]` is a one-character string.
Concatenate with `+`, compare lexicographically with `<` and friends.

```rust
let s = "rscp" + "!"
println(s[0], len(s), s == "rscp!")    // r 5 true
```

---

## Grammar

```ebnf
program        := statement* EOF ;

statement      := letStmt | fnStmt | ifStmt | whileStmt | loopStmt | forStmt
                | returnStmt | breakStmt | continueStmt | block
                | assignment | incDec | exprStmt | ";" ;

letStmt        := ("let" | "var") IDENT "=" expression [";"] ;
fnStmt         := "fn" IDENT funcBody ;
funcBody       := "(" [ paramList ] ")" ( block | "->" expression ) ;
paramList      := IDENT { "," IDENT } [ "," ] ;   (* trailing comma ok *)

ifStmt         := "if" expression block
                  [ "else" ( ifStmt | block ) ] ;  (* '(' cond ')' also ok *)
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
block          := "{" ( statement | ";" )* "}" ;

assignment     := target ( "=" | "+=" | "-=" | "*=" | "/=" | "%=" ) expression [";"] ;
incDec         := target ( "++" | "--" ) [";"] ;
target         := IDENT | postfix "[" expression "]" ;
exprStmt       := expression [";"] ;

expression     := ternary ;
ternary        := range [ "?" expression ":" ternary ] ;
range          := logicOr [ ( ".." | "..=" ) logicOr ] ; (* for iterables only *)
logicOr        := logicAnd { "||" logicAnd } ;
logicAnd       := equality { "&&" equality } ;
equality       := comparison { ( "==" | "!=" ) comparison } ;
comparison     := term { ( "<" | "<=" | ">" | ">=" ) term } ;
term           := factor { ( "+" | "-" ) factor } ;
factor         := unary { ( "*" | "/" | "%" ) unary } ;
unary          := ( "!" | "-" ) unary | postfix ;
postfix        := primary { "(" [ arguments ] ")" | "[" expression "]" } ;
arguments      := expression { "," expression } [ "," ] ;
primary        := INT | FLOAT | STRING | "true" | "false" | "null" | IDENT
                | "(" expression ")" | arrayLit | mapLit | "fn" funcBody
                | closure ;
closure        := ( "|" paramList "|" | "||" ) ( expression | block ) ;
arrayLit       := "[" [ expression { "," expression } [ "," ] ] "]" ;
mapLit         := "{" [ expression ":" expression { "," … } [ "," ] ] "}" ;
```

A `;` is inserted automatically after a newline (or the end of input) when
the line ends with a value, `)`, `]`, `}`, `++`, `--`, `return`, `break` or
`continue` — and the next token cannot continue an expression (a `}`, `]`,
`)`, `,`, `:`, `?`, `else`, `->`, `..` suppresses the insertion). A `{` at
statement position always starts a block; a map literal in that position
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
| `src/bytecode.rscp` | 39 opcodes, chunks, prototypes, disassembler |
| `src/compiler.rscp` | AST → bytecode; locals, upvalue capture, loop patching |
| `src/value.rscp`  | runtime values (`Rc`/`RefCell` reference types) |
| `src/vm.rscp`     | stack machine: frames, call stack, upvalue closing |
| `src/builtins.rscp` | 19 native functions |
| `src/main.rscp`   | CLI (`run`, `repl`, `disasm`, `tokens`, `ast`) |

Design highlights:

* **Bytecode, not tree-walking.** Programs compile once into a `Chunk` of
  39 one-byte opcodes (with `u8`/`u16` operands); the VM is a tight dispatch
  loop over call frames. `for i in 0..n` compiles to a counted loop — no
  array is built (same speed as the legacy C-style `for`).
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

* **44 unit tests** across lexer (including the semicolon-insertion rules),
  parser (both syntax styles), compiler and VM (including closure
  semantics, mutability rules and error cases).
* **72 golden cases** in `tests/cases/`: each program's exact stdout is
  pinned in a `.out` file; error programs pin the exit code and a required
  stderr fragment in `.err` files. The suite spans every feature and every
  error class in this README, both the light and the legacy syntax.
* **6 showcase examples** are smoke-tested (`examples/`).
* The CLI surface itself is tested (exit codes, subcommands).

---

## RSCP vs Python vs Rust — where it sits

| | Python | Rust | RSCP |
|---|---|---|---|
| semicolons | none | required | optional (newline ends the statement) |
| blocks | indentation | braces | braces (required) |
| condition parens | no | no | no (optional, legacy form accepts them) |
| bindings | implicit | `let` / `let mut` | `let` / `var` |
| functions | `def f(x):` | `fn f(x) { }` | `fn f(x) { }` or `fn f(x) -> expr` |
| lambdas | `lambda x: x` | `\|x\| x` | `\|x\| x` |
| loops | `for i in range(n)` | `for i in 0..n` | `for i in 0..n` |
| infinite loop | `while True:` | `loop { }` | `loop { }` |
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
(`2026.2.1` in this release). The full four-number version lives in
`rscp version`, the REPL banner, release tags (`v2026.2.1.0`), release
file names and this README. Every release is published on GitHub as a tag
with the source zip, the Windows zip and the `.vsix` attached.

## Changelog

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
