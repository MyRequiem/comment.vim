" s:GetCommentChars(...) {{{1
function! s:GetCommentChars(...) abort
    if len(a:000)
        let l:comment_string = !empty(a:1) ? a:1 : g:comment_default_chars
    else
        let l:ft = substitute(&filetype, '\v\.', '_', 'g')

        if empty(l:ft)
            let l:comment_string = g:comment_default_chars
        else
            let l:comment_string = get(g:,'comment_' . l:ft . '_chars', '')
            if empty(l:comment_string)
                let l:comment_string = !empty(&commentstring) ?
                    \ &commentstring : g:comment_default_chars
            endif
        endif
    endif

    let l:comment_chars = split(l:comment_string, '%s')

    return [
                \ substitute(l:comment_chars[0], '\v\s+$', '', 'g'),
                \ len(l:comment_chars) > 1 ?
                    \ substitute(l:comment_chars[1], '\v^\s+', '', 'g') : ''
          \]
endfunction " 1}}}

" s:isAlreadyAllCommented(range, comment_chrs) {{{1
function! s:isAlreadyAllCommented(range, comment_chrs)
    let l:count = 0
    for l:line_num in a:range
        if !empty(matchstr(getline(l:line_num),
                         \ '\v^\s*' . escape(a:comment_chrs[0], '/*><$^(){%@&'))
                \)
            let l:count += 1
        endif
    endfor

    return len(a:range) == l:count
endfunction " 1}}}

" s:getIndentLen() {{{1
function! s:getIndentLen(str)
    return len(matchstr(a:str, '\v^\s*'))
endfunction " 1}}}

" s:getMinIndent(lines) {{{1
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

    return  exists('l:min_indent') && l:min_indent > 1 ? l:min_indent : 0
endfunction " 1}}}

" s:getBlankString(len) {{{1
function! s:getBlankString(len)
    let l:blank = ''
    for l:space in range(a:len)
        let l:blank .= ' '
    endfor

    return l:blank
endfunction " 1}}}

" comment#CommentLines(...) range abort {{{1
function! comment#CommentLines(...) range abort
    if len(a:000)
        let l:comment_chars = s:GetCommentChars(
            \ input('Enter comment characters in &commentstring format: ')
        \)

        execute 'normal! :<Esc>'
    else
        let l:comment_chars = s:GetCommentChars()
    endif

    let l:line_range        = range(a:firstline, a:lastline)
    let l:min_indent        = s:getMinIndent(l:line_range)
    let l:already_commented = s:isAlreadyAllCommented(l:line_range,
                                                 \ l:comment_chars)
    for l:line_num in l:line_range
        let l:str_is_empty = empty(getline(l:line_num))
        let l:double_symb  = !empty(l:comment_chars[1])
        let l:str_content  = getline(l:line_num)

        if l:already_commented
            let l:blank_len = s:getIndentLen(l:str_content)
            let l:blank     = l:blank_len ? s:getBlankString(l:blank_len) : ''
            let l:new_line  = printf('%s%s', l:blank, l:str_content[
                        \l:blank_len + len(l:comment_chars[0]) + 1:
                        \l:double_symb ? -len(l:comment_chars[1]) - 2 : -1
                    \])

            silent call setline(l:line_num, l:new_line)
            continue
        endif

        if l:str_is_empty && (!g:comment_blank_lines || l:double_symb)
            continue
        endif

        let l:blank = l:min_indent ? s:getBlankString(l:min_indent) : ''
        let l:new_line = printf('%s%s%s%s',
                    \ l:blank,
                    \ l:comment_chars[0] . (l:str_is_empty ? '' : ' '),
                    \ l:str_content[l:min_indent :],
                    \ l:double_symb ? ' ' . l:comment_chars[1] : '')

        silent call setline(l:line_num, l:new_line)
    endfor
endfunction " 1}}}
