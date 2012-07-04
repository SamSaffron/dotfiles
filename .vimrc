set nocompatible
source $VIMRUNTIME/vimrc_example.vim
source $VIMRUNTIME/mswin.vim
behave mswin

set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let eq = ''
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      let cmd = '""' . $VIMRUNTIME . '\diff"'
      let eq = '"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction

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
set guifont=Consolas:h14
let Grep_Skip_Dirs = 'log nbproject doc vendor .svn prototype'
map <F12> :set number!<CR>
map <C-TAB> :tabnext<CR>
map <C-S-TAB> :tabprevious<CR>
let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1 
let g:rubycomplete_rails = 1

" add better nav
autocmd User Rails Rnavcommand dcomponent app/assets/javascripts/discourse/components -glob=* -suffix=
autocmd User Rails Rnavcommand dhelper app/assets/javascripts/discourse/helpers -glob=* -suffix=.coffee
autocmd User Rails Rnavcommand dmodel app/assets/javascripts/discourse/models -glob=* -suffix=.coffee
autocmd User Rails Rnavcommand dtemplate app/assets/javascripts/discourse/templates -glob=* -suffix=.handlebars
autocmd User Rails Rnavcommand dview app/assets/javascripts/discourse/views -glob=* -suffix=.coffee
autocmd User Rails Rnavcommand config -glob=*.* -suffix= -default=routes.rb
" change to current dir - needs work 
map ,e :e <C-R>=expand("%:p:h") . "/" <CR> 

silent! ruby nil
set completeopt=longest,menuone
inoremap <expr> <cr> pumvisible() ? "\<c-y>" : "\<c-g>u\<cr>" 
inoremap <expr> <c-n> pumvisible() ? "\<lt>c-n>" : "\<lt>c-n>\<lt>c-r>=pumvisible() ? \"\\<lt>down>\" : \"\"\<lt>cr>"
inoremap <expr> <m-;> pumvisible() ? "\<lt>c-n>" : "\<lt>c-x>\<lt>c-o>\<lt>c-n>\<lt>c-p>\<lt>c-r>=pumvisible() ? \"\\<lt>down>\" : \"\"\<lt>cr>" 
map <F9> :previous<CR>
map <f10> :next<CR> 
imap <C-c> <Esc>:w<cr>

set nohls
