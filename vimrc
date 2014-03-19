function! NumToggle()
	if(&rnu == 1)
		set nu
	else
		set rnu
	endif
endfunc

set nocompatible

filetype indent plugin on

syntax on

set showcmd

set ignorecase
set smartcase

set backspace=indent,eol,start

set autoindent

set ruler

set visualbell

set mouse=a

set number

set ts=4
set sw=4

nnoremap <C-n> :call NumToggle()<cr>
