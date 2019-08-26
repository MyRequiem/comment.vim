" s:GetCommentChars(...) {{{1
" param:  string or null
" return: list of comment characters
function! s:GetCommentChars(...) abort
    if len(a:000)
        " comment characters entered from the keyboard (if nothing is entered
        " then used g:comment_default_chars)
        let l:comment_string = !empty(a:1) ? a:1 : g:comment_default_chars
    else
        " replace dots with underscore in variable &filetype
        " (for example: c.doxygen -> c_doxygen)
        let l:ft = substitute(&filetype, '\v\.', '_', 'g')

        if empty(l:ft)
            " file type is empty string
            let l:comment_string = g:comment_default_chars
        else
            let l:comment_string = get(g:,'comment_' . l:ft . '_chars', '')
            " if g:comment_<filetype>_chars is not defined in 'vimrc',
            " then use &commentstring. If &commentstring is empty use
            " g:comment_default_chars
            if empty(l:comment_string)
                let l:comment_string = !empty(&commentstring) ?
                    \ &commentstring : g:comment_default_chars
            endif
        endif
    endif

    let l:comment_chars = split(l:comment_string, '%s')

    " remove trailing and leading spaces
    return [
                \ substitute(l:comment_chars[0], '\v\s+$', '', 'g'),
                \ len(l:comment_chars) > 1 ?
                    \ substitute(l:comment_chars[1], '\v^\s+', '', 'g') : ''
          \]
endfunction " 1}}}

" s:isAlreadyAllCommented(range, comment_chrs) {{{1
" param:  list of line numbers
" param:  list of comment characters
" return: 0 or 1
function! s:isAlreadyAllCommented(range, comment_chrs) abort
    " number of commented lines
    let l:count = 0
    for l:line_num in a:range
        if !empty(matchstr(getline(l:line_num),
                        \ '\v^\s*' . escape(a:comment_chrs[0], '/*><$^(){%@&|'))
                \)
            let l:count += 1
        endif
    endfor

    return len(a:range) == l:count
endfunction " 1}}}

" s:getIndentLen(str) {{{1
" param:  string
" return: integer
function! s:getIndentLen(str) abort
    return len(matchstr(a:str, '\v^\s*'))
endfunction " 1}}}

" s:getMinIndent(line_range) {{{1
" param:  list of line numbers
" return: integer
function! s:getMinIndent(line_range) abort
    let l:min_flag = 0

    for l:line_num in a:line_range
        let l:line_content  = getline(l:line_num)
        let l:line_is_empty = empty(l:line_content)

        if l:line_is_empty && !g:comment_blank_lines
            continue
        elseif l:line_is_empty
            return 0
        endif

        let l:cur_indent = s:getIndentLen(l:line_content)

        if !l:cur_indent
            return 0
        endif

        if !l:min_flag
            let l:min_indent = l:cur_indent
            let l:min_flag   = 1
        else
            let l:min_indent = min([l:cur_indent, l:min_indent])
        endif
    endfor

    " if the indent of the first character in the line = 1
    " then comment from the beginning of the line
    return  exists('l:min_indent') && l:min_indent > 1 ? l:min_indent : 0
endfunction " 1}}}

" s:getBlankString(len) {{{1
" param:  integer
" return: string
function! s:getBlankString(len) abort
    let l:blank = ''
    for l:space in range(a:len)
        let l:blank .= ' '
    endfor

    return l:blank
endfunction " 1}}}

" s:isSpaceAfterComment(str, comment_chars) {{{1
" param:  string
" param:  list of comment characters
" return: 0 or 1
function s:isSpaceAfterComment(str, comment_chars) abort
    return !empty(matchstr(a:str, '\v^\s*' .
        \ escape(a:comment_chars[0], '/*><$^(){%@&') . '\s'))
endfunction " 1}}}

" comment#CommentLines(mode) range {{{1
function! comment#CommentLines(mode) range abort
    " a:mode = 0    - default comment character depending on file type and
    "                   &commentstring (if &filetype is not set used
    "                   g:comment_default_chars). If &commentstring is not set
    "                   used g:comment_default_chars () (default hotkey: gc)
    " a:mode = 1    - input a comment character from the keyboard
    "                   (default hotkey: gC)
    if a:mode
        let l:comment_chars = s:GetCommentChars(
            \ input('Enter comment characters in &commentstring format ' .
                \ '['. g:comment_default_chars . ']: ')
        \)

        execute 'normal! :<Esc>'
    else
        let l:comment_chars = s:GetCommentChars()
    endif

    " list of line numbers
    let l:line_range        = range(a:firstline, a:lastline)
    " minimum indent for all lines
    let l:min_indent        = s:getMinIndent(l:line_range)
    let l:blank_min_str     = s:getBlankString(l:min_indent)
    let l:already_commented = s:isAlreadyAllCommented(l:line_range,
                                                    \ l:comment_chars)
    for l:line_num in l:line_range
        " current line is empty
        let l:str_is_empty = empty(getline(l:line_num))
        " comment consists of leading and trailing characters
        let l:double_symb  = !empty(l:comment_chars[1])
        let l:str_content  = getline(l:line_num)

        " uncomment
        if l:already_commented
            let l:indent_len = s:getIndentLen(l:str_content)
            let l:blank_str  = s:getBlankString(l:indent_len)
            let l:new_line   = printf('%s%s', l:blank_str, l:str_content[
                    \l:indent_len + len(l:comment_chars[0]) +
                        \ (s:isSpaceAfterComment(l:str_content,
                                               \ l:comment_chars) ? 1 : 0):
                    \l:double_symb ? -len(l:comment_chars[1]) - 2 : -1
                \])

            silent call setline(l:line_num, l:new_line)
            continue
        endif

        " do not comment blank lines if g:comment_blank_lines is
        " not set or comment characters have a start and end part
        if l:str_is_empty && (!g:comment_blank_lines || l:double_symb)
            continue
        endif

        " comment
        let l:new_line  = printf('%s%s%s%s',
                    \ l:blank_min_str,
                    \ l:comment_chars[0] . (l:str_is_empty ? '' : ' '),
                    \ l:str_content[l:min_indent :],
                    \ l:double_symb ? ' ' . l:comment_chars[1] : '')

        silent call setline(l:line_num, l:new_line)
    endfor
endfunction " 1}}}
