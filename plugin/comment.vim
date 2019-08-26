" File:         comment.vim
" Type:         utility
" Version:      1.0
" Date:         26.08.19
" Author:       MyRequiem <mrvladislavovich@gmail.com>
" License:      MIT
" Description:  File-type sensible comments

scriptencoding utf-8

if exists('g:loaded_comment') && g:loaded_comment
    finish
endif

let g:loaded_comment = 1

let g:comment_blank_lines     = get(g:, 'comment_blank_lines', 1)
let g:comment_hotkey          = get(g:, 'comment_hotkey', 'gcc')
let g:comment_hotkey_manually = get(g:, 'comment_hotkey_manually', 'gC')
let g:comment_default_chars   = get(g:, 'comment_default_chars', '/* %s */')

execute 'nnoremap <silent>' . g:comment_hotkey .
    \ ' :call comment#CommentLines(0)<cr>'
execute 'vnoremap <silent>' . g:comment_hotkey .
    \ ' :call comment#CommentLines(0)<cr>'

execute 'nnoremap <silent>' . g:comment_hotkey_manually .
    \ ' :call comment#CommentLines(1)<cr>'
execute 'vnoremap <silent>' . g:comment_hotkey_manually .
    \ ' :call comment#CommentLines(1)<cr>'
