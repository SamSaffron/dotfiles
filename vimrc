runtime bundle/vim-pathogen/autoload/pathogen.vim
call pathogen#infect()
set nocompatible
colorscheme vividchalk
syntax on
filetype plugin indent on
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set autoindent
set smartindent
set cindent
set guifont=Consolas\ 14
let Grep_Skip_Dirs = 'log nbproject doc vendor .svn prototype'
map <F12> :set number!<CR>
map <C-TAB> :tabnext<CR>
map <C-S-TAB> :tabprevious<CR>
let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
let g:rubycomplete_rails = 1

" add better nav
" autocmd User Rails Rnavcommand dcomponent app/assets/javascripts/discourse/components -glob=* -suffix=.js
" autocmd User Rails Rnavcommand droute app/assets/javascripts/discourse/routes -glob=* -suffix=.js
" autocmd User Rails Rnavcommand dcontroller app/assets/javascripts/discourse/controllers -glob=* -suffix=.js
" autocmd User Rails Rnavcommand dhelper app/assets/javascripts/discourse/helpers -glob=* -suffix=.js
" autocmd User Rails Rnavcommand dmodel app/assets/javascripts/discourse/models -glob=* -suffix=*
" autocmd User Rails Rnavcommand dtemplate app/assets/javascripts/discourse/templates -glob=**/* -suffix=.handlebars
" autocmd User Rails Rnavcommand dview app/assets/javascripts/discourse/views -glob=**/* -suffix=.js
" autocmd User Rails Rnavcommand config -glob=*.* -suffix= -default=routes.rb
" autocmd User Rails Rnavcommand serializer app/serializers -glob=* -suffix=.rb
" change to current dir - needs work
map ,e :e <C-R>=expand("%:p:h") . "/" <CR>

silent! ruby nil
set completeopt=longest,menuone
map <F9> :previous<CR>
map <f10> :next<CR>
imap <C-c> <Esc>:w<cr>

let g:ackprg = 'ag --nogroup --nocolor --column'
set noantialias

au BufNewFile,BufRead Guardfile set filetype=ruby
au BufNewFile,BufRead *.pill set filetype=ruby
au BufNewFile,BufRead *.es6 set filetype=javascript
au BufNewFile,BufRead *.es6.erb set filetype=javascript

nmap <C-a> <Esc>:!touch tmp/restart<CR><CR>
nmap <C-s> <Esc>:!touch tmp/refresh_browser<CR><CR>

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set t_Co=256

function! MRIIndent()
  setlocal cindent
  setlocal noexpandtab
  setlocal shiftwidth=4
  setlocal softtabstop=4
  setlocal tabstop=8
  setlocal textwidth=80
  " Ensure function return types are not indented
  setlocal cinoptions=(0,t0
endfunction

autocmd Filetype c,cpp call MRIIndent()

let g:ctrlp_match_func = {'match' : 'pymatcher#PyMatch' }
let g:ctrlp_user_command = {
  \ 'types': {
    \ 1: ['.git', 'cd %s && git ls-files --cached --exclude-standard --others']
    \ },
  \ 'fallback': 'find %s -type f'
  \ }

se guioptions=agim
set mouse=a

filetype off
filetype plugin indent off
set runtimepath+=/usr/local/go/misc/vim
filetype plugin indent on
syntax on

let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
    \ }

" let g:syntastic_javascript_checkers = ['eslint']
" let g:syntastic_ruby_checkers = ['mri', 'rubocop']
let g:ale_linters = { 'javascript': ['eslint'] }

let g:ale_lint_on_text_changed = 'never'

if &term =~ "xterm.*"
    let &t_ti = &t_ti . "\e[?2004h"
    let &t_te = "\e[?2004l" . &t_te
    function XTermPasteBegin(ret)
        set pastetoggle=<Esc>[201~
        set paste
        return a:ret
    endfunction
    map <expr> <Esc>[200~ XTermPasteBegin("i")
    imap <expr> <Esc>[200~ XTermPasteBegin("")
    cmap <Esc>[200~ <nop>
    cmap <Esc>[201~ <nop>
endif

autocmd QuickFixCmdPost *grep* cwindow

cabbrev Ack Ack!

set ttymouse=sgr
set mouse=a


function s:notify_file_change()
  let root = rails#app().path()
  let notify = root . "/bin/notify_file_change"
  if executable(notify)
    if executable('socat')
      execute "!" . notify . ' ' . expand("%:p") . " " . line(".")
    end
  end
  " redraw!
endfunction

autocmd BufWritePost * silent! call s:notify_file_change()
set backspace=indent,eol,start

