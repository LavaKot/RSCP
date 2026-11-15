" Vim syntax file for RSCP 2026.3.0.0
" Place in ~/.vim/syntax/rscp.vim (or ~/.config/nvim/syntax/rscp.vim),
" together with the ftdetect rule from editors/vim/ftdetect/rscp.vim.

if exists("b:current_syntax")
  finish
endif

" Keywords
syntax keyword rscpConditional if else match
syntax keyword rscpRepeat while loop for in
syntax keyword rscpStatement return break continue
syntax keyword rscpKeyword fn let var
syntax keyword rscpBoolean true false
syntax keyword rscpConstant null

" Built-in functions
syntax keyword rscpBuiltin print println len str int float type abs min max
syntax keyword rscpBuiltin sqrt pow rand clock push pop keys has assert panic

" Comments
syntax match rscpComment "//.*$" contains=rscpTodo
syntax region rscpComment start="/\*" end="\*/" contains=rscpTodo
syntax keyword rscpTodo TODO FIXME XXX NOTE contained

" Strings with escapes
syntax region rscpString start=/"/ skip=/\\./ end=/"/ contains=rscpEscape
syntax match rscpEscape +\\[ntr0\\"']+ contained

" Numbers: hex, floats (but not the dots of a range), integers
syntax match rscpNumber "\<0[xX][0-9a-fA-F_]\+\>"
syntax match rscpNumber "\<0[bB][01_]\+\>"
syntax match rscpNumber "\<0[oO][0-7_]\+\>"
syntax match rscpFloat "\<\(\d[\d_]*\)\=\.\d[\d_]*\([eE][+-]\=\d\+\)\=\>"
syntax match rscpFloat "\<\d[\d_]*\.\=[eE][+-]\=\d\+\>"
syntax match rscpNumber "\<\d[\d_]*\>"

" Function definitions and calls
syntax match rscpFuncDef "\<fn\s\+\h\w*" contains=rscpKeyword
syntax match rscpFuncCall "\<\h\w*\s*\ze("

" Operators (ranges and arrow first so they win over - and .)
syntax match rscpRange "\.\.=\=\."
syntax match rscpArrow "->"
syntax match rscpArrow "=>"
syntax match rscpOperator "<<=\|>>=\|<<\|>>\|&=\||=\|\^=\|&\|\^\|~\|&&\|||\|!\|==\|!=\|<=\|>=\|<\|>\|+\|-\|\*\|/\|%\|=\|?\|:\|++\|--\|+="

" Short closure pipes |x|
syntax match rscpPipe "|"

" Highlighting links (works with most color schemes)
hi def link rscpConditional Conditional
hi def link rscpRepeat Repeat
hi def link rscpStatement Statement
hi def link rscpKeyword Keyword
hi def link rscpBoolean Boolean
hi def link rscpConstant Constant
hi def link rscpBuiltin Function
hi def link rscpComment Comment
hi def link rscpTodo Todo
hi def link rscpString String
hi def link rscpEscape Special
hi def link rscpNumber Number
hi def link rscpFloat Float
hi def link rscpFuncDef Function
hi def link rscpFuncCall Function
hi def link rscpRange Special
hi def link rscpArrow Special
hi def link rscpOperator Operator
hi def link rscpPipe Delimiter

let b:current_syntax = "rscp"
