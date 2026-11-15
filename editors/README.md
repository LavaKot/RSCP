# RSCP в любом редакторе

Файлы `.rscp` — обычный текст в UTF-8, поэтому их откроет что угодно, от
Блокнота до `cat`. Этот каталог добавляет то, что превращает «откроет» в
«удобно»: подсветку синтаксиса, парные скобки и сниппеты.

| Редактор | Что даёт | Куда положить |
|---|---|---|
| **VS Code / VSCodium / Cursor** | подсветка, сниппеты, скобки | готовый `vscode/rscp-26.0.12.11.vsix`: `code --install-extension vscode/rscp-26.0.12.11.vsix` |
| **Vim / Neovim** | подсветка | `vim/syntax/rscp.vim` → `~/.vim/syntax/`, `vim/ftdetect/rscp.vim` → `~/.vim/ftdetect/` |
| **Sublime Text 3/4** | подсветка | `sublime/RSCP.tmLanguage` → `~/.config/sublime-text/Packages/RSCP/` |
| **Notepad++** | подсветка, свёртка `{ }` | `notepad++/rscp-udl.xml` → Language → User Defined Language → Import |
| **Любой другой** | «чужая» подсветка | см. запасные ассоциации ниже |

Подробности по каждому — в README внутри соответствующей подпапки
(`vscode/README.md` — на русском, с задачей запуска по `Ctrl+Shift+B`).

## Запасные ассоциации (одна строка, без установки чего-либо)

RSCP 26.0.12.11 унаследовал ключевые слова от Rust, а структуру блока — от C,
поэтому «чужие» подсветки смотрятся почти родными:

* **VS Code / Cursor** (`settings.json`):
  `"files.associations": { "*.rscp": "rust" }`
* **Vim** (`~/.vimrc`): `autocmd BufRead,BufNewFile *.rscp set filetype=rust`
* **Sublime Text**: открыть `.rscp`, затем View → Syntax → Open all with
  current extension as… → Rust
* **Notepad++**: Settings → Style Configurator → User Ext.: `rscp` (в поле
  выбранного языка, например C)

## Windows: «Открыть с помощью» для `.rscp`

Файл ассоциируется со всем сразу через реестр (запустите от администратора,
`assoc-rscp.bat` ниже); проще — правый клик по файлу → *Открыть с помощью* →
выбрать редактор и включить «Всегда». Текст `.rscp` — обычный UTF-8, поэтому
подойдёт любой редактор: VS Code, Notepad++, Блокнот.

## Что подсвечивается (одинаково во всех редакторах)

* ключевые слова: `fn let var if else while loop for in return break continue`
* константы: `true false null`, числа: `42 3.14 0xFF 1_000 1e-3`
* строки с экранированием, комментарии `#` до конца строки (TODO/FIXME подсвечиваются)
* встроенные функции: `println len push keys …` (перед `(`)
* операторы, включая диапазоны `0..10` / `0..=9`, стрелку `->` и пайпы `|x|`
