" let s:bcs = b:current_syntax
"
" unlet b:current_syntax
" syntax include @HTML syntax/html.vim
"
" unlet b:current_syntax
" syntax include @SQL syntax/sql.vim
"
" unlet b:current_syntax
" syntax include @MD syntax/markdown.vim
"
" let b:current_syntax = s:bcs
"
" syntax region heredocHtml matchgroup=Statement start=+<<[-~.]*\z(HTML\)+ end=+^\s*\z1+ contains=@HTML
" syntax region heredocSQL matchgroup=Statement start=+<<[-~.]*\z(SQL\)+ end=+^\s*\z1+ contains=@SQL
" syntax region heredocMarkdown matchgroup=Statement start=+<<[-~.]*\z(MD\)+ end=+^\s*\z1+ contains=@MD
