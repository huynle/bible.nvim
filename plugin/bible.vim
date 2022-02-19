" plugin/bible.vim
" What have i done plugin!
if exists('g:loaded_bible') | finish | endif

" let s:save_cpo = &cpo
" set cpo&vim

" hi def link bibleHeader      Number
" hi def link bibleSubHeader   Identifier

" command! BibleInit lua require'bible'
lua require'bible'

" let &cpo = s:save_cpo
" unlet s:save_cpo

" lua require

let g:loaded_bible = 1


