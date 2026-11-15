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

# FizzBuzz, the light way — no ';' anywhere.
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

> **Beta.** RSCP is young and released under `26.0.x.y` beta versioning —
> see [Versioning](#versioning). Found a bug? Please
> [report it](https://github.com/LavaKot/RSCP/issues) — see [Bugs](#bugs).

---

## Why RSCP

* **One binary, zero setup.** The whole language is a single ~10 MB
  executable with no runtime, no package manager and no dependencies —
  download, run, done. It works offline and starts instantly, which makes
  it a comfortable glue for everyday scripts.
* **Light like Python.** No semicolons, no type annotations, f-strings,
  slices with negative bounds (`a[1:3]`, `a[::-1]`), `match` expressions,
  `and`/`or`/`not`, `#` comments — the syntax stays out of the way.
* **Shaped like Rust.** Braces, `fn`/`let`/`var`, ranges `0..10`,
  closures `|x| x * 2`, `loop { }` and checked arithmetic: integer overflow
  and division by zero are clean errors, not silent wraps. Skills and
  habits transfer in both directions.
* **A real compiler, not a tree-walker.** Programs compile once into a
  chunk of 62 one-byte opcodes; the VM is a tight dispatch loop. A `for`
  loop runs on **fused instructions** — the whole loop head (compare,
  branch, element refresh) is one opcode, and a pure counted loop costs
  ~18 ns per iteration.
* **Batteries included.** Classes with inheritance, modules, `try`/`catch`,
  30+ builtins (`split`, `replace`, `keys`, `assert`, …) and a REPL ship in
  the box — no standard library to install first.
* **Enums with real exhaustiveness.** `enum Shape { Circle, Rect(w, h) }`
  destructures in `match` and the compiler rejects a non-exhaustive match,
  naming the missing variants — like Rust, not like a runtime `switch`.
* **Typed, catchable errors.** Every runtime error is an object with a
  stable `code` (`DIV_ZERO`, `MISSING_KEY`, …), a message and a structured
  `detail`; `catch e code "X"` / `catch e where …` filter by code or
  condition, and unmatched errors rethrow unchanged. Compile errors point
  at the exact character; uncaught runtime errors carry a full stack trace.
* **Readable in one evening.** The entire compiler + VM is ~9 000 lines of
  plain, safe Rust with `std` only and no `unsafe` — a textbook
  implementation you can actually study and extend.
* **Your editor already knows it.** A VS Code / VSCodium / Cursor
  extension (highlighting + snippets), plus Vim, Sublime Text and
  Notepad++ support, ship in the repo.

The full language tour, grammar and reference live in a separate
documentation project: **[LavaKot/RSCP-docs](https://github.com/LavaKot/RSCP-docs)**
(rendered as a site: <https://lavakot.github.io/RSCP-docs/>).

---

## Downloads

Every release on the [releases page](https://github.com/LavaKot/RSCP/releases)
carries the same set of files (replace `<version>` with the release number,
e.g. `26.0.7.0`):

* `rscp-<version>-windows-x64-setup.exe` — Windows installer: copies the
  files, adds itself to the user PATH, registers an uninstaller
* `rscp-<version>-linux-x64-installer.sh` — self-extracting Linux installer
  (run it; binary to `~/.local/bin`, examples and the VS Code plugin to
  `~/.local/share/rscp`; supports `--to DIR` and `--uninstall`)
* `rscp-<version>-windows-x64.zip` — ready-to-run Windows build (`rscp.exe`,
  examples, VS Code plugin, installer guide in Russian)
* `rscp-<version>.zip` — full sources
* `rscp-<version>.vsix` — VS Code / VSCodium / Cursor extension

### Windows

Run the installer — `rscp` is available **immediately**, even in terminal
windows that were already open (the installer drops an instant alias into
`WindowsApps`, the same mechanism that makes `python` work right away):

```
rscp version
rscp examples\fizzbuzz.rscp
```

Prefer the archive? Unzip `rscp-<version>-windows-x64.zip` to a permanent
place (e.g. `C:\rscp`) and double-click `add-to-path.cmd` — it sets up the
PATH and the instant alias the same way. `remove-from-path.cmd` undoes it.
The editor plugin is `rscp-<version>.vsix`.

Staying up to date is one command (the repository is public — no token
needed):

```
rscp update
```

### Linux

```sh
./rscp-<version>-linux-x64-installer.sh     # binary -> ~/.local/bin
rscp version
```

### From source

Requirements: a Rust toolchain (1.75+; tested with 1.100).

```sh
./build.sh              # debug build + full test suite
./build.sh release      # optimized binary at target/release/rscp
```

---

## The toolchain

```sh
rscp hello.rscp                    # run a program (extension shortcut)
rscp run hello.rscp                # explicit form
rscp repl                          # interactive session
rscp disasm hello.rscp             # inspect the bytecode
rscp tokens hello.rscp             # inspect the token stream
rscp ast hello.rscp                # inspect the parse tree
rscp fmt hello.rscp                # print the formatted code
rscp fmt -w hello.rscp             # ...or rewrite the file in place
rscp update                        # self-update from GitHub (Windows)
```

A REPL taste:

```
$ rscp repl
rscp 26.0.12.0 — enter statements, Ctrl-D to exit.
rscp> let double = |x| x * 2
rscp> double(21)
42
rscp> for i in 0..3 { print(i) }
012
```

`rscp fmt` is a conservative formatter: it re-emits the token stream
without reordering or dropping anything (only redundant `;` disappear), so
comments and string literals survive verbatim and running it twice changes
nothing.

RSCP is portable: the whole implementation is plain Rust + `std`, so the
same source builds natively on Windows, Linux and macOS. Editor support
ships in [`editors/`](editors/README.md): a real VS Code extension
(`code --install-extension editors/vscode/rscp-26.0.12.0.vsix`), Vim,
Sublime Text, Notepad++, and a Windows Explorer file association.

---

## Bugs

RSCP is beta software — rough edges are expected, and reports make it
better. **If something breaks, please tell us:**
[open an issue](https://github.com/LavaKot/RSCP/issues) with

* what you ran (the smallest `.rscp` file that reproduces it),
* what you expected and what happened instead,
* your RSCP version (`rscp version`) and OS.

Questions, ideas and tutorial requests are welcome in the same place.

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
| `src/fmt.rscp`    | `rscp fmt` — token-level formatter |
| `src/errors.rscp` | unified error type, source-annotated rendering |
| `src/fxhash.rscp` | FxHash-style hasher for globals and maps |
| `src/bytecode.rscp` | 62 opcodes, chunks, prototypes, disassembler |
| `src/compiler.rscp` | AST → bytecode; locals, upvalue capture, loop patching |
| `src/value.rscp`  | runtime values (`Rc`/`RefCell` reference types) |
| `src/vm.rscp`     | stack machine: frames, call stack, upvalue closing |
| `src/builtins.rscp` | native functions |
| `src/main.rscp`   | CLI (`run`, `repl`, `disasm`, `tokens`, `ast`, `fmt`) |

Design highlights:

* **Bytecode, not tree-walking.** Programs compile once into a `Chunk` of
  62 one-byte opcodes (with `u8`/`u16` operands); the VM is a tight dispatch
  loop over call frames. `for i in 0..n` compiles to a counted loop — no
  array is built — whose head is a single fused instruction, and `match`
  compiles to a jump chain.
* **Proper closures.** Captured locals are shared *upvalue* cells that stay
  "open" (pointing into the stack) while the defining scope runs and close
  (copying the value out) when it returns — two closures made in the same
  scope observe the same variable, exactly like C++ lambdas by reference.
* **Checked arithmetic.** Integer overflow, division and modulo by zero are
  clean runtime errors with a stack trace — not undefined behavior.
* **Reference types are explicit.** `let a = [1]; let b = a;` aliases; `==`
  on arrays/maps compares identity, on numbers/strings compares values.
* **No `unsafe`, no dependencies.** The whole implementation is safe Rust
  and `std` only; `cargo build` needs no network.

Implementation limits (locals per function, constants per chunk, …) are
listed in the [docs](https://github.com/LavaKot/RSCP-docs).

---

## Performance

26.0.9.0 was a dedicated speed release: no new syntax — the same programs
run faster. Measured with `bench/bench.py` (best of 5 runs, x86-64 Linux,
26.0.8.0 as the baseline):

| Workload                        | 26.0.8.0 | 26.0.9.0 | Speedup |
|---------------------------------|---------:|---------:|--------:|
| `fib(30)` — recursion, 2.7M calls | 468 ms | 388 ms | 1.21× |
| 10M-iteration arithmetic loop   | 2772 ms  | 1593 ms  | 1.74× |
| global read-modify-write ×2M    | 380 ms   | 128 ms   | 2.98× |
| array build + two indexed passes | 375 ms | 166 ms   | 2.26× |
| map dot-access (`m.a = i`, …)   | 416 ms   | 207 ms   | 2.01× |
| 3M method calls (OOP)           | 1452 ms  | 908 ms   | 1.60× |
| string split/join/replace/find  | 119 ms   | 88 ms    | 1.36× |
| printing 100k lines (piped)     | 105 ms   | 22 ms    | 4.82× |
| **geometric mean**              |          |          | **1.89×** |

A pure counted loop (`for i in 0..10_000_000 { }`) went from ~52 to
~18 ns per iteration. What changed under the hood:

* **No allocations on name lookups.** Global and map keys became `Rc<str>`
  (a lookup moves a refcount, not a heap block), and SipHash gave way to an
  FxHash-style hasher (`src/fxhash.rscp`) — the same family rustc uses.
* **Fused loop instructions.** The whole `for` head — compare, branch,
  loop-variable refresh — is one opcode (`ForRange`/`ForArray`), the counter
  bump is one more (`IncLocal`), and statement conditions pop the bool right
  in the jump (`JumpIfFalsePop`). A range loop runs 3 dispatches per
  iteration where it used to run 7; an array loop 3 instead of 9.
* **In-place arithmetic and comparisons** — binary ops update the operand
  slot instead of a pop/push pair.
* **Reusable argument buffer** for native calls (no `Vec` allocation per
  `push`/`str`/`join`/… call).
* **Block-buffered stdout when piped** (like Python), line-buffered on a
  terminal, with the same quiet `exit 141` on broken pipes.

Reproduce with `python3 bench/bench.py target/release/rscp` — the suite
ships in `bench/`.

---

## Testing

```sh
cargo test
```

The suite combines unit tests across lexer, parser, compiler and VM,
106 golden cases in `tests/cases/` (each program's exact stdout, exit code
and stderr pinned), and the CLI surface itself. The 12 showcase examples in
`examples/` are smoke-tested in CI on Ubuntu, Windows and macOS.

---

## Versioning

RSCP versions are four numbers: **`YY.0.MINOR.PATCH`** (until 26.0.7.0 the
scheme was `YEAR.MAJOR.MINOR.PATCH` — `2026.6.0.0` — and the minor counter
carries over; this is feature release #12).

| Number | Counts what | Example |
|--------|-------------|---------|
| 1st | year, short form (26 = 2026) | `26` |
| 2nd | `0` while RSCP is in beta, `1` from the first stable release | `0` |
| 3rd | feature releases — one number per shipped feature set | `12` |
| 4th | patches (fixes) within a feature release | `0` |

So this release is `26.0.10.0` (`v26.0.12.0`); a hotfix on top of it would
be `26.0.10.1`, and the next feature release `26.0.11.0`. While the second
number is `0`, GitHub releases are titled **"Beta …"** (e.g. "Beta
26.0.10.0"); from the first stable release the prefix disappears.

A tooling note: Cargo and npm manifests only accept three-number semver, so
`Cargo.toml` and the VS Code `package.json` carry the first three numbers
(`26.0.12` in this release). The full four-number version lives in
`rscp version`, the REPL banner, release tags, release file names and this
README.

## Changelog

* **26.0.12.0** — get(), literal payload patterns, and the calculator
  example. `get(m, k, default?)` is the Option-style read: the value or the
  default (null) when the key is missing — maps, arrays and strings,
  negative indexes from the end; only wrong container types raise (`ARG`).
  Enum-variant patterns now accept **literal payload elements** —
  `Ast.Bin("+", l, r)` matches only the `+` case — plus `_` and bindings,
  via a new fused `ArgsIs` opcode (65 total); alternations must agree on
  fields. `examples/calc.rscp` is a full expression calculator (tokenizer →
  enum AST → evaluator) showcasing enums, exhaustiveness, typed errors and
  selective catch. The docs gained a "Honest limits" section. 69 unit
  tests, 112 golden cases.
* **26.0.11.0** — enum sum types with compile-time exhaustiveness.
* **26.0.11.0** — enum sum types with compile-time exhaustiveness.
  `enum Shape { Circle, Rect(w, h), Point }`: unit variants are values,
  tuple variants are constructor functions; `match` destructures payloads
  (`Shape.Rect(w, h) => w * h`) and the compiler rejects non-exhaustive
  matches by naming the missing variants — the Rust guarantee, dynamically
  scoped to same-file enums. Variants print as `Shape.Rect(3, 4)`, `type()`
  returns the enum name, `==` is structural, `x instanceof Shape` accepts
  any variant, and two new fused opcodes (`EnumIs`/`EnumBind` — 64 total)
  run the pattern tests. Also fixed a pre-existing grammar bug: match guards
  ending in an identifier (`k if done => 1`) used to parse as an arrow
  closure. 69 unit tests, 111 golden cases.
* **26.0.10.0** — typed errors. Every runtime error now carries a stable
* **26.0.10.0** — typed errors. Every runtime error now carries a stable
  machine-readable **code** (`DIV_ZERO`, `IDX_RANGE`, `MISSING_KEY`,
  `UNDEFINED_VAR`, `ARITY`, `TYPE`, `ASSERT`, `PANIC`, `NO_ARM`, `USER`,
  … — the full table is in the docs), and the `catch` binding became an
  **error object**: `e.code`, `e.message` and a structured `e.detail`
  (`try { [1][9] } catch e { e.detail.length }`). `print(e)` still shows
  just the message, so existing programs keep their output. **Selective
  catch**: a `try` may carry several clauses — `catch e code "DIV_ZERO" { }`
  matches one code, `catch e where e.code != "X" { }` filters by any
  condition — and when all clauses decline, the original error is rethrown
  unchanged. New `error(code, message, detail?)` builtin builds typed
  errors for `throw`; `throw e` of an existing error object preserves it
  (codes and custom fields survive); a thrown map may carry its own
  `code`/`message`. `match` with no matching arm now reports code `NO_ARM`
  instead of `PANIC`. Under the hood: helpers and builtins return a boxed
  `RtError`, and the cold paths (throw, arity raises, class construction)
  moved out of the dispatch loop — the suite is a net **1.01× faster** than
  26.0.9.0 (loops 1.06×, globals/arrays 1.02×; map-heavy writes −7%).
  67 unit tests, 105 golden cases.
* **26.0.9.0** — the speed release: **1.89× faster on average (geometric
  mean), up to 4.8× on printing** — see the new Performance section for the
  full table. No new syntax: the same programs run faster. Global and map
  lookups stopped allocating (`Rc<str>` keys everywhere) and switched from
  SipHash to an FxHash-style hasher; `for` loop heads compile to single
  fused instructions (`JumpIfFalsePop`, `IncLocal`, `ForRange…`, `ForArray`
  — 62 opcodes now), so a pure counted loop runs ~18 ns per iteration
  (was ~52); binary ops and comparisons update stack slots in place;
  native calls reuse an argument buffer instead of allocating a `Vec` per
  call; stdout is block-buffered when piped (like Python) with the same
  line-buffered terminal behavior and the same quiet `exit 141` on broken
  pipes. A 9-workload benchmark suite now ships in `bench/`. 67 unit tests,
  106 golden cases.
* **26.0.8.0** — `rscp` works right after install, like `python`. The
  Windows installer (and the new `add-to-path.cmd` in the zip) now puts an
  instant alias — a copy of `rscp.exe` — into
  `%LOCALAPPDATA%\Microsoft\WindowsApps`, a folder that sits on the user
  PATH of every process, so the `rscp` command works even in terminals
  opened *before* the install. The PATH write itself became safer: entries
  like `%USERPROFILE%\bin` and the `REG_EXPAND_SZ` registry type are
  preserved, `WM_SETTINGCHANGE` is broadcast so new terminals pick the PATH
  up without a logoff, and a direct registry write replaces PowerShell when
  it is unavailable. `rscp update` now updates the alias too (and resolves
  the real install directory when launched through it).
* **26.0.7.0** — new home, new numbering, new license. The repository is
  public and renamed **rscp → RSCP** (old `LavaKot/rscp` links redirect
  automatically), which also makes `rscp update` work **without a GitHub
  token**. Versioning switched from `YEAR.MAJOR.MINOR.PATCH` (`2026.6.0.0`)
  to the short **`26.0.MINOR.PATCH`** form — the minor counter carries over
  from the old scheme, beta releases are titled "Beta …" on GitHub. The
  tutorials, language tour, grammar and reference tables moved to a separate
  documentation project, [LavaKot/RSCP-docs](https://github.com/LavaKot/RSCP-docs)
  (also rendered as a website), and this README became a compact project
  card: why RSCP is worth a try, downloads, the changelog. The license now
  explicitly **forbids copying the project and passing it off as your own**
  (forks and reuse with credit are welcome).
* **2026.6.0.0** — object-oriented programming. `class Name(Parent) { fn
  method(...) { } }` with constructor calls `Name(args)`, `init` methods,
  an injected `self`, field access `self.x`, method dispatch up the
  inheritance chain, `super.method(...)`, `instanceof`, `type(instance)`
  returning the class name and `<Dog instance>` printing. Classes are
  immutable maps under the hood and instances are maps with a `__class__`
  reference — no new value type, everything composes. New opcodes
  `CallMethod` / `SuperMethod` / `InstanceOf`. 64 unit tests, 106 golden
  cases, new `examples/oop.rscp`.
* **2026.5.6.0** — readability. `rscp fmt` — a conservative, comment-
  preserving formatter (one statement per line, 4-space indentation,
  canonical spacing; `-w` rewrites in place, output always parses to the
  same program and is idempotent). Arrow closures `x => expr` and
  `(a, b) => expr` join the `|x|` form. `if`/`else`/`while`/`loop`/`for`
  bodies may be a single statement without braces: `if ok print(x)`.
  63 unit tests, 105 golden cases.
* **2026.5.5.0** — `print` and friends. `print(...)` is now the Python-style
  primary: it ends the line (`println` stays as an alias, and the no-newline
  form is the new `write`). `nil` and `none` are synonyms of `null`.
  `var x` without an initializer declares `x` as `null`; `let` still
  requires one. 60 unit tests, 104 golden cases.
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
  `cursor` CLI is present. The golden suite no longer hardcodes the version
  string.
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

Use it, fork it, teach with it. The license grants the usual MIT-style
freedoms **with one binding condition**: you may not copy this project (in
whole or in substantial part) and present it as your own work — forks and
reuse must preserve the license and credit
[LavaKot/RSCP](https://github.com/LavaKot/RSCP). The full text is in
[LICENSE](LICENSE).
