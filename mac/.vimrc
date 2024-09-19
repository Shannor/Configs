set surround
set which-key

set timeoutlen = 7000

inoremap jk <ESC>
let mapleader = ","

set relativenumber
set number
set nocompatible

" Stop bad habits
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
nnoremap j gj
nnoremap k gk

" Split screen vertically
nnoremap <leader>w <C-w>v<C-w>l
" Split horizontally
nnoremap <leader>q <C-w>s<C-w>l

" Change into a screen based on direction
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
