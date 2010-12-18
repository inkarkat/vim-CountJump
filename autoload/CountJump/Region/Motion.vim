" CountJump#Region#Motion.vim: Create custom motions via jumps over matching
" lines. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	18-Dec-2010	file creation

"			Move around ???
"]x, ]]			Go to [count] next start of ???. 
"]X, ][			Go to [count] next end of ???. 
"[x, [[			Go to [count] previous start of ???. 
"[X, []			Go to [count] previous end of ???. 

function! CountJump#Region#Motion#MakeBracketMotion( mapArgs, keyAfterBracket, inverseKeyAfterBracket, pattern, isMatch, ... )
"*******************************************************************************
"* PURPOSE:
"   Define a complete set of mappings for a [x / ]x motion (e.g. like the
"   built-in ]m "Jump to start of next method") that support an optional [count]
"   and jump over regions of lines which are defined by contiguous lines that
"   (don't) match a:pattern. 
"   The mappings work in normal mode (jump), visual mode (expand selection) and
"   operator-pending mode (execute operator). 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"
"* EFFECTS / POSTCONDITIONS:
"   Creates mappings for normal, visual and operator-pending mode: 
"	Normal mode: Jumps to the <count>th region. 
"	Visual mode: Extends the selection to the <count>th region. 
"	Operator-pending mode: Applies the operator to the covered text. 
"	If there aren't <count> more regions, a beep is emitted. 
"
"* INPUTS:
"   a:mapArgs	Arguments to the :map command, like '<buffer>' for a
"		buffer-local mapping. 
"   a:keyAfterBracket	Mapping key [sequence] after the mandatory ]/[ which
"			start the mapping for a motion to the beginning of a
"			block. 
"			Can be empty; the resulting mappings are then omitted. 
"   a:inverseKeyAfterBracket	Likewise, but for the motions to the end of a
"				block. Usually the uppercased version of
"				a:keyAfterBracket. 
"				Can be empty; the resulting mappings are then
"				omitted. 
"   If both a:keyAfterBracket and a:inverseKeyAfterBracket are empty, the
"   default [[ and ]] mappings are overwritten. (Note that this is different
"   from passing ']' and '[', respectively, because the back motions are
"   swapped.) 
"   a:pattern	Regular expression that defines the region, i.e. must (not)
"		match in all lines belonging to it. 
"   a:isMatch	Flag whether to search matching (vs. non-matching) lines. 
"   a:mapModes		Optional string containing 'n', 'o' and/or 'v',
"			representing the modes for which mappings should be
"			created. Defaults to all modes. 
"
"* RETURN VALUES: 
"   None. 
"*******************************************************************************
    let l:mapModes = split((a:0 ? a:1 : 'nov'), '\zs')

    let l:dataset = []
    if empty(a:keyAfterBracket) && empty(a:inverseKeyAfterBracket)
	call add(l:dataset, ['[[', -1, 1])
	call add(l:dataset, [']]', 1, 0])
	call add(l:dataset, ['[]', -1, 0])
	call add(l:dataset, ['][', 1, 1])
    else
	if ! empty(a:keyAfterBracket)
	    call add(l:dataset, ['[' . a:keyAfterBracket, -1, 1])
	    call add(l:dataset, [']' . a:keyAfterBracket, 1, 0])
	endif
	if ! empty(a:inverseKeyAfterBracket)
	    call add(l:dataset, ['[' . a:inverseKeyAfterBracket, -1, 0])
	    call add(l:dataset, [']' . a:inverseKeyAfterBracket, 1, 1])
	endif
    endif

    for l:mode in l:mapModes
	for l:data in l:dataset
	    execute escape(
	    \   printf("%snoremap <silent> %s %s :<C-U>call CountJump#JumpFunc(%s, 'CountJump#Region#JumpToNextRegion', %s, %d, %d, %d)<CR>",
	    \	    (l:mode ==# 'v' ? 'x' : l:mode),
	    \	    a:mapArgs,
	    \	    l:data[0],
	    \	    string(l:mode),
	    \	    string(a:pattern),
	    \	    a:isMatch,
	    \	    l:data[1],
	    \	    l:data[2]
	    \   ), '|'
	    \)
	endfor
    endfor
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
