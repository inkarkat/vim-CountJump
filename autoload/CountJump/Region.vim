" Region.vim: summary
"
" DEPENDENCIES:
"
" Copyright: (C) 2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	21-Jul-2010	file creation

function! s:SearchInLineMatching( line, pattern, isMatch )
    if a:line < 1 || a:line > line('$')
	return 0
    endif

    let l:col = match(getline(a:line), a:pattern)
    if (l:col == -1 && a:isMatch) || (l:col != -1 && ! a:isMatch)
	return 0
    endif

    return l:col + 1	" Screen columns start at 1, match returns zero-based index. 
endfunction
function! s:SearchForLastLineContinuouslyMatching( startLine, pattern, isMatch, step )
"******************************************************************************
"* PURPOSE:
"   Search for the last line (from a:startLine, using a:step as direction) that
"   matches (or not, according to a:isMatch) a:pattern. 
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. Does not change the cursor position. 
"* INPUTS:
"   a:startLine	Line in the current buffer where the search starts. Can be an
"		invalid one. 
"   a:pattern	Regular expression to match. 
"   a:isMatch	Flag whether to search matching or non-matching lines. 
"   a:step	Increment to go to next line. Use 1 for forward, -1 for backward
"		search. 
"* RETURN VALUES: 
"   [ line, col ] of the (first match) in the last line that continuously (not)
"   matches, or [0, 0] if no such (non-)match. 
"******************************************************************************
    let l:line = a:startLine
    let l:foundPosition = [0, 0]
    while 1
	let l:col = s:SearchInLineMatching(l:line, a:pattern, a:isMatch)
	if l:col == 0 | break | endif
	let l:foundPosition = [l:line, l:col]
	let l:line += a:step
    endwhile
    return l:foundPosition
endfunction
function! CountJump#Region#SearchForRegionEnd( count, pattern, step )
"******************************************************************************
"* PURPOSE:
"   Starting from the current line, search for the position where the a:count'th
"   region (as defined by contiguous lines that match a:pattern) ends. 
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:count Number of regions to cover. 
"   a:pattern	Regular expression that defines the region, i.e. must match in
"		all lines belonging to it. 
"   a:step	Increment to go to next line. Use 1 for forward, -1 for backward
"		search. 
"* RETURN VALUES: 
"   [ line, col ] of the (first match) in the last line that continuously (not)
"   matches, or [0, 0] if no such (non-)match. 
"******************************************************************************
    let l:c = a:count
    let l:line = line('.')
    while 1
	" Search for the current region's end. 
	let [l:line, l:col] = s:SearchForLastLineContinuouslyMatching(l:line, a:pattern, 1, a:step)
	if l:line == 0
	    return [0, 0]
	endif

	" If this is the last region to be found, we're done. 
	let l:c -= 1
	if l:c == 0
	    break
	endif

	" Otherwise, search for the next region's start. 
	let l:line += a:step
	let [l:line, l:col] = s:SearchForLastLineContinuouslyMatching(l:line, a:pattern, 0, a:step)
	if l:line == 0
	    return [0, 0]
	endif

	let l:line += a:step
    endwhile

    call setpos('.', [0, l:line, l:col, 0])
    normal! zv
    return [l:line, l:col]
endfunction
function! CountJump#Region#SearchForNextRegion( count, pattern, step, isEnd )
"******************************************************************************
"* PURPOSE:
"   Starting from the current line, search for the position where the a:count'th
"   region (as defined by contiguous lines that match a:pattern) begins/ends. 
"   If the current line is inside the border of a region, jumps to the next one.
"   If it is actually inside a region, jumps to the current region's border. 
"   This makes it work like the built-in motions: [[, ]], etc. 
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:count Number of regions to cover. 
"   a:pattern	Regular expression that defines the region, i.e. must match in
"		all lines belonging to it. 
"   a:step	Increment to go to next line. Use 1 for forward, -1 for backward
"		search. 
"   a:isEnd	Flag whether to search for the end of the region. 
"* RETURN VALUES: 
"   [ line, col ] of the (first match) in the last line that continuously (not)
"   matches, or [0, 0] if no such (non-)match. 
"******************************************************************************
    let l:c = a:count
    let l:isDone = 0
    let l:line = line('.')

    " Check whether we're currently on the border of a region. 
    let l:isInRegion = (s:SearchInLineMatching(l:line, a:pattern, 1) != 0)
    let l:isNextInRegion = (s:SearchInLineMatching((l:line + a:step), a:pattern, 1) != 0)
    if l:isInRegion
	if l:isNextInRegion
	    " We're inside a region; search for the current region's end. 
	    let [l:line, l:col] = s:SearchForLastLineContinuouslyMatching(l:line, a:pattern, 1, a:step)
	    if l:c == 1 && a:isEnd 
		" We're done already! 
		let l:isDone = 1
	    else
		" We've moved to the border, start the search from the next line
		" so that we move out of the current region. 
		let l:line += a:step
	    endif
	else
	    " We're on the border, start the search from the next line so that we
	    " move out of the current region. 
	    let l:line += a:step
	endif
    endif

    while ! l:isDone
	" Search for the next region's start. 
	let [l:line, l:col] = s:SearchForLastLineContinuouslyMatching(l:line, a:pattern, 0, a:step)
	if l:line == 0
	    return [0, 0]
	endif
	let l:line += a:step

	" If this is the last region to be found, we're almost done. 
	let l:c -= 1
	if l:c == 0
	    if a:isEnd
		" Search for the current region's end. 
		let [l:line, l:col] = s:SearchForLastLineContinuouslyMatching(l:line, a:pattern, 1, a:step)
		if l:line == 0
		    return [0, 0]
		endif
	    else
		" Check whether another region starts at the current line. 
		let l:col = s:SearchInLineMatching(l:line, a:pattern, 1)
		if l:col == 0
		    return [0, 0]
		endif
	    endif

	    break
	endif

	" Otherwise, we're not done; skip over the next region. 
	let [l:line, l:col] = s:SearchForLastLineContinuouslyMatching(l:line, a:pattern, 1, a:step)
	if l:line == 0
	    return [0, 0]
	endif
	let l:line += a:step
    endwhile

    call setpos('.', [0, l:line, l:col, 0])
    normal! zv
    return [l:line, l:col]
endfunction

function! CountJump#Region#Jump( mode, JumpFunc, ... )
"*******************************************************************************
"* PURPOSE:
"   Implement a custom motion by jumping to the <count>th occurrence of the
"   passed pattern. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"
"* EFFECTS / POSTCONDITIONS:
"   Normal mode: Jumps to the <count>th occurrence. 
"   Visual mode: Extends the selection to the <count>th occurrence. 
"   If the jump doesn't work, a beep is emitted. 
"
"* INPUTS:
"   a:mode  Mode in which the search is invoked. Either 'n', 'v' or 'o'. 
"	    With 'O': Special additional treatment for operator-pending mode
"	    with a pattern to end. 
"   a:JumpFunc		Function which is invoked to jump. 
"   The jump function must take at least one argument:
"	a:count	Number of matches to jump to. 
"   It can take more arguments which must then be passed in here: 
"   ...	    Arguments to the passed a:JumpFunc
"
"* RETURN VALUES: 
"   List with the line and column position, or [0, 0], like searchpos(). 
"*******************************************************************************
    let l:save_view = winsaveview()

    if a:mode ==# 'v'
	normal! gv
    endif

    if a:mode ==# 'O'
	" Special additional treatment for operator-pending mode with a pattern
	" to end. 
	let l:matchPos = call(a:JumpFunc, [v:count1] + a:000)
	if l:matchPos != [0, 0]
	    " The difference between normal mode, visual and operator-pending 
	    " mode is that in the latter, the motion must go _past_ the final
	    " character, so that all characters are selected. This is done by
	    " appending a 'l' motion after the search. 
	    "
	    " In operator-pending mode, the 'l' motion only works properly
	    " at the end of the line (i.e. when the moved-over "word" is at
	    " the end of the line) when the 'l' motion is allowed to move
	    " over to the next line. Thus, the 'l' motion is added
	    " temporarily to the global 'whichwrap' setting. 
	    " Without this, the motion would leave out the last character in
	    " the line. I've also experimented with temporarily setting
	    " "set virtualedit=onemore", but that didn't work. 
	    let l:save_ww = &whichwrap
	    set whichwrap+=l
	    normal! l
	    let &whichwrap = l:save_ww
	else
	    " TODO: beep
	endif
	return l:matchPos
    endif

    let l:matchPos = call(a:JumpFunc, [v:count1] + a:000)
    if l:matchPos == [0, 0]
	" Ring the bell to indicate that no match exists. 
	"
	" As long as this mapping does not exist, it causes a beep in both
	" normal and visual mode. This is easier than the customary "normal!
	" \<Esc>", which only works in normal mode. 
	execute "normal \<Plug>RingTheBell"
    else
	" Add the original cursor position to the jump list. 
	call winrestview(l:save_view)
	normal! m'
	call setpos('.', [0] + l:matchPos + [0])
    endif

    return l:matchPos
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
