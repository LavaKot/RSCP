# RSCP для VS Code

Официальное расширение языка RSCP 2026.2.1.1: подсветка синтаксиса (включая новые
диапазоны `0..n`, короткие замыкания `|x| x` и стрелочные функции `->`),
сниппеты, автозакрытие скобок и кавычек, комментарии по `Ctrl+/`, автосдвиг
от `{ }`. Работает в VS Code, VSCodium, Cursor и других редакторах на базе
VS Code.

## Установка — способ 1, готовый пакет `.vsix` (рекомендуется)

В дистрибутиве уже лежит собранный пакет `rscp-2026.2.1.1.vsix` (рядом с этим
файлом). Установите его одной командой:

```sh
code --install-extension rscp-2026.2.1.1.vsix
```

- **VSCodium:** `codium --install-extension rscp-2026.2.1.1.vsix`
- **Cursor:** `cursor --install-extension rscp-2026.2.1.1.vsix`
- **Через интерфейс:** Extensions (`Ctrl+Shift+X`) → `…` → *Install from
  VSIX…* → выбрать файл.

Перезапустите редактор, откройте любой `.rscp` файл — внизу справа должно
быть написано `RSCP`.

## Установка — способ 2, вручную из папки

1. Скопируйте папку `editors/vscode` целиком в
   `%USERPROFILE%\.vscode\extensions\rscp-2026.2.1.1`
   (Linux/macOS: `~/.vscode/extensions/rscp-2026.2.1.1`).
2. Перезапустите VS Code.

## Установка — способ 3, без расширения (одна строка настроек)

RSCP похож на Rust по ключевым словам, поэтому как запасной вариант можно
сказать VS Code: «считай `.rscp` файлами Rust»:

```json
"files.associations": { "*.rscp": "rust" }
```

Подсветка появится сразу, перезапуск не нужен. Минус: подсветка «чужая» —
`println`, `loop` и диапазоны `0..n` будут подсвечены не как родные.

## Сниппеты

Начните печатать префикс и нажмите `Tab`:

| Префикс | Разворачивается в |
|---|---|
| `let` / `var` | привязка |
| `fn` | функция с телом-блоком |
| `fna` | `fn name(params) -> выражение` |
| `cl` | короткое замыкание `\|x\| x * 2` |
| `if` / `ife` | условие / условие с else |
| `while` / `loop` | циклы |
| `forr` / `forri` | `for i in 0..n` / `for i in 0..=n` |
| `forin` | `for item in collection` |
| `forc` | классический `for (var i = 0; …)` (совместимость) |
| `pl` | `println(...)` |
| `main` | `fn main() { ... }` |

## Запуск программ из VS Code

Добавьте в `.vscode/tasks.json` своего проекта (создайте, если его нет):

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "RSCP: run current file",
      "type": "shell",
      "command": "rscp",
      "args": ["${file}"],
      "group": { "kind": "build", "isDefault": true },
      "presentation": { "clear": true, "reveal": "always" }
    }
  ]
}
```

Чтобы команда `rscp` находилась, положите `rscp.exe` (или `rscp`) в `PATH`,
либо замените `"command": "rscp"` на полный путь, например
`"C:\\tools\\rscp\\rscp.exe"`. После этого `Ctrl+Shift+B` запускает
текущий открытый `.rscp` файл.

## Что подсвечивается

| Элемент | Пример |
|---|---|
| ключевые слова | `fn let var if else while loop for in return break continue` |
| константы | `true false null` |
| числа | `42 3.14 0xFF 1_000 1e-3` |
| строки | `"hi\n"` с экранированием |
| комментарии | `//` и `/* */` |
| встроенные функции | `println len push keys ...` (перед `(`) |
| свои функции | `fn makeCounter`, вызовы `makeCounter()` |
| диапазоны | `0..10`, `0..=9` |
| стрелка и пайпы | `->`, `\|x\|` |
| операторы | `+ - * / % == != && \|\| ? : += ++ ..` |

Грамматика — стандартная TextMate (`syntaxes/rscp.tmLanguage.json`),
поэтому её же подхватывают Sublime Text и другие TextMate-редакторы
(см. `editors/README.md`).
