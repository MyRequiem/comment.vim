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

let g:comment_blank_lines = get(g:, 'comment_blank_lines', 1)
let g:comment_default_chars = get(g:, 'comment_default_chars', '/*%s*/')

nnoremap <silent>gc :call comment#CommentLines()<cr>
vnoremap <silent>gc :call comment#CommentLines()<cr>

nnoremap <silent>gC :call comment#CommentLines(1)<cr>
vnoremap <silent>gC :call comment#CommentLines(1)<cr>
