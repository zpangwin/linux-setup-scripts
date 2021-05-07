" leave this alone - compatible disables lots of vim features and puts it in backwards compatible mode
set nocompatible

" Remap Ctrl+S to write (:w) to avoid locking terminal. Note: if this happens use Ctrl+Q to resume.
" May also require dealing with stty issues by adding the following to ~/.bashrc: stty -ixon
:nnoremap <c-s> :w<CR>
:inoremap <c-s> <Esc>:w<CR>a

" Make backspace work like in most other editors
" May also require dealing with stty issues by adding the following to ~/.bashrc: stty erase '^?'
set backspace=indent,eol,start

" Make tabs 4 spaces wide and do not replace tabs with spaces
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab

" Enable syntax highlighting
syntax on

" Fix bug in newer versions of vim where it ignores "highlight Comment"
" https://vi.stackexchange.com/questions/4044/vimrc-contents-selectively-i-e-highlight-ignored
set background=light

" Change the color of commented blocks to green (default is a light blue very similar to variable names)
highlight Comment ctermfg=DarkGreen

