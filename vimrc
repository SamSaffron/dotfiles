packadd minpac

call minpac#init()

" a pretty color scheme
call minpac#add('morhetz/gruvbox')

" prettifier of JavaScript es6 code
call minpac#add('prettier/vim-prettier')

" awesome async syntax linting
call minpac#add('w0rp/ale')

" Git support note, considering dropping this
" cause gina is async which helps a lot
call minpac#add('tpope/vim-fugitive')
call minpac#add('lambdalisue/gina.vim')

" es6 syntax in vim appears a bit rough
" this makes it better and supports stuff like `test`
call minpac#add('isRuslan/vim-es6')

" official ruby support
call minpac#add('vim-ruby/vim-ruby')

" awesome rails support
call minpac#add('tpope/vim-rails')

call minpac#add('tpope/vim-endwise')
call minpac#add('tpope/vim-repeat')
call minpac#add('tpope/vim-surround')
call minpac#add('tpope/vim-haml')
call minpac#add('tpope/vim-unimpaired')
call minpac#add('tpope/vim-markdown')
call minpac#add('tpope/vim-abolish')

" very cool highlighting of recently yanked text
call minpac#add('machakann/vim-highlightedyank')

" :Gist to send a gist to Gist, webapi
" is a plugin dependency
call minpac#add('mattn/webapi-vim')
call minpac#add('mattn/gist-vim')

" file explorer with :NERDTree
call minpac#add('scrooloose/nerdtree')

" search across all files quickly
call minpac#add('mileszs/ack.vim')
call minpac#add('tomtom/tcomment_vim')
call minpac#add('Townk/vim-autoclose')
call minpac#add('juvenn/mustache')

" can be used to see if stuff is indented right
call minpac#add('nathanaelkane/vim-indent-guides')
call minpac#add('vim-scripts/taglist.vim')
call minpac#add('groenewege/vim-less')
call minpac#add('csexton/trailertrash.vim')
call minpac#add('Blackrush/vim-gocode')
call minpac#add('danchoi/ri.vim')

" I prefer using tab for autocompletion
" habit from old visual studio days
call minpac#add('ervandew/supertab')

call minpac#add('dgryski/vim-godef')
call minpac#add('majutsushi/tagbar')
call minpac#add('rodjek/vim-puppet')

" tries to keep track of focus when we pick a file
" from quick fix window, better than always opening the wrong file
call minpac#add('yssl/QFEnter')

" fzf is an awesome fuzzy file finder I map it to CTRL-P
call minpac#add('junegunn/fzf', { 'dir': '~/.fzf', 'do': './install -all' })
call minpac#add('junegunn/fzf.vim')

if has('nvim')
  call minpac#add('vimlab/split-term.vim')
  " %s/test/test1 will perform replacement in-place
  set inccommand=nosplit
  " cause it likes an I-Beam without this
  set guicursor=
  set mouse=a
end

if !has('nvim')
  " sensible is enabled by default in nvim
  call minpac#add('tpope/vim-sensible')
  " I prefer no antialiasing on osx
  set noantialias

  " a Autoselect so its easy to select from vim into
  " other apps
  " g grey inactive menu items
  " i use vim icon
  " m show the menubar
  set guioptions=agim

  set ttymouse=sgr
  set mouse=a
  " This hack seems to only work in vim
  " protect indenting when pasting in stuff
  " in normal mode
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
  end
end

command! PackUpdate call minpac#update()
command! PackClean call minpac#clean()

syntax on
filetype plugin indent on
set nocompatible
set termguicolors
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set autoindent
set smartindent
set cindent
set guifont=Consolas\ 14
set hlsearch
set incsearch

let mapleader=" "
nnoremap <SPACE> <Nop>

map <F12> :set number!<CR>
map <C-TAB> :tabnext<CR>
map <C-S-TAB> :tabprevious<CR>

let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
let g:rubycomplete_rails = 1

" disable auto format for now even if // @format comment is there
let g:prettier#autoformat = 0

" I am used to CTRL-p so use it, additionally allow for some extra
" help in normal/visual mode
nmap <leader>h <plug>(fzf-maps-n)
xmap <leader>h <plug>(fzf-maps-x)
nmap <C-p> :GFiles -co --exclude-standard<cr>

silent! ruby nil
set completeopt=longest,menuone
map <F9> :previous<CR>
map <f10> :next<CR>

" the silver searcher is way faster than ack
let g:ackprg = 'ag --nogroup --nocolor --column'

au BufNewFile,BufRead Guardfile set filetype=ruby
au BufNewFile,BufRead *.pill set filetype=ruby
au BufNewFile,BufRead *.es6 set filetype=javascript
au BufNewFile,BufRead *.es6.erb set filetype=javascript

" Discourse specific helpers that force browser refresh / restart
nmap <leader>a :!touch tmp/restart<CR><CR>
nmap <leader>s :!touch tmp/refresh_browser<CR><CR>
" I prefer to check in with a GUI then using fugitive or Gina
nmap <silent> <leader>g :!git gui &<CR><CR>
" hlsearch can be very annoying if you rely on it a lot so
" leader l is a nice way of quickly hiding it
nmap <silent> <leader>l :nohlsearch<CR>
nmap <silent> <leader>t :Tagbar<CR>

" I find CTRL-W CTRL-L etc. for changing windows so awkward
" ALT -> right etc is so much simpler
nmap <silent> <A-Up> :wincmd k<CR>
nmap <silent> <A-Down> :wincmd j<CR>
nmap <silent> <A-Left> :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR>

" force more colors in vim, not sure it is needed anymore in
" 8 cause I am already forcing gui colors
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

" Ruby conventions for MRI source code
autocmd Filetype c,cpp call MRIIndent()

filetype off
filetype plugin indent off
set runtimepath+=/usr/local/go/misc/vim
filetype plugin indent on

" :TagBar displays a split to the right that allows
" us to navigate current file, these are rules for Ruby
" and Go
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

let g:tagbar_type_ruby = {
    \ 'kinds' : [
        \ 'm:modules',
        \ 'c:classes',
        \ 'd:describes',
        \ 'C:contexts',
        \ 'f:methods',
        \ 'F:singleton methods'
    \ ]
\ }

if executable('ripper-tags')
  let g:tagbar_type_ruby = {
      \ 'kinds'      : ['m:modules',
                      \ 'c:classes',
                      \ 'C:constants',
                      \ 'F:singleton methods',
                      \ 'f:methods',
                      \ 'a:aliases'],
      \ 'kind2scope' : { 'c' : 'class',
                       \ 'm' : 'class' },
      \ 'scope2kind' : { 'class' : 'c' },
      \ 'ctagsbin'   : 'ripper-tags',
      \ 'ctagsargs'  : ['-f', '-']
      \ }
endif

let g:ale_linters = { 'javascript': ['eslint'] }
let g:ale_lint_on_text_changed = 'never'

" open quick fix window after :Ggrep
autocmd QuickFixCmdPost *grep* cwindow

cabbrev Ack Ack!

" Discourse specific, on save we will notify
" the exact position where a spec was saved
" this allows us to run the spec at the exact right spot
function s:notify_file_change_discourse()
  let root = rails#app().path()
  let notify = root . "/bin/notify_file_change"
  if executable(notify)
    if executable('socat')
      execute "!" . notify . ' ' . expand("%:p") . " " . line(".")
    end
  end
  " redraw!
endfunction
autocmd BufWritePost * silent! call s:notify_file_change_discourse()

set backspace=indent,eol,start

" we use pupped a lot and we need saner indent
function! PuppetIndent()
  setlocal noexpandtab
  setlocal shiftwidth=4
  setlocal softtabstop=4
  setlocal tabstop=4
  setlocal textwidth=80
endfunction
autocmd Filetype puppet call PuppetIndent()

" very annoying default behavior
let g:puppet_align_hashes = 0

" gruvbox default contrast is not enough for me
let g:gruvbox_contrast_dark="hard"
set background=dark
colorscheme gruvbox


" I find the amount folding ruby does to be too much of the folding way too much
let ruby_foldable_group="def"

