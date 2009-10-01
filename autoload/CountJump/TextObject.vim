" CountJump#TextObject.vim: Create custom text objects via repeated jumps (or searches). 
"
" DEPENDENCIES:
"
" Copyright: (C) 2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	14-Feb-2009	Renamed from 'custommotion.vim' to
"				'CountJump.vim' and split off motion and
"				text object parts. 

function! s:Escape( argumentText )
    return substitute(a:argumentText, "'", "''", 'g')
endfunction

"			Select text delimited by ???. 
"ix			Select [count] text blocks delimited by ??? without the
"			outer delimiters. 
"ax			Select [count] text blocks delimited by ??? including
"			the delimiters. 
function! CountJump#TextObject#TextObjectWithJumpFunctions( isInner, selectionMode, JumpToBegin, JumpToEnd )
"*******************************************************************************
"* PURPOSE:
"	? What the procedure does (not how).
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"	? Explanation of each argument that isn't obvious.
"* RETURN VALUES: 
"	? Explanation of the value returned.
"* TODO:
"   - Check whether jumps actually move around the cursor position, and not
"     delimit a block somewhere else. 
"*******************************************************************************
    let l:count = v:count1
    let l:isExclusive = (&selection ==# 'exclusive')
    let l:isLinewise = (a:selectionMode ==# 'V')

    let l:save_whichwrap = &whichwrap
    set whichwrap+=h,l
    try
	if call(a:JumpToBegin, [1, a:isInner])
	    if a:isInner
		if l:isLinewise
		    normal! j
		else
		    normal! l
		endif
	    endif
	    execute 'normal!' a:selectionMode
	    if call(a:JumpToEnd, [l:count, a:isInner])
		if l:isLinewise && a:isInner
		    normal! k
		else
		    if ! l:isExclusive && a:isInner
			normal! h
		    elseif l:isExclusive && ! a:isInner
			normal! l
		    endif
		endif
	    endif
	endif
    finally
	let &whichwrap = l:save_whichwrap
    endtry
endfunction
function! CountJump#TextObject#MakeWithJumpFunctions( mapArgs, textObjectKey, types, selectionMode, JumpToBegin, JumpToEnd )
"*******************************************************************************
"* PURPOSE:
"   Define a complete set of mappings for inner and/or outer text objects that
"   support an optional [count] and are driven by two functions that jump to the
"   beginning and end of a block. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"
"* EFFECTS / POSTCONDITIONS:
"   Creates mappings for operator-pending and visual mode which act upon /
"   select the text delimited by the locations where the two functions jump to. 
"
"* INPUTS:
"   a:mapArgs	Arguments to the :map command, like '<buffer>' for a
"		buffer-local mapping. 
"   a:textObjectKey	Mapping key [sequence] after the mandatory i/a which
"			start the mapping for the text object. 
"   a:types		String containing 'i' for inner and 'a' for outer text
"			objects. 
"   a:selectionMode	Type of selection used between the patterns:
"			'v' for characterwise, 'V' for linewise, '<CTRL-V>' for
"			blockwise. 
"			In linewise mode, the inner text objects do not contain
"			the complete lines matching the pattern. 
"   a:JumpToBegin	Function which is invoked to jump to the begin of the
"			block. 
"   a:JumpToEnd		Function which is invoked to jump to the end of the
"			block. 
"   The jump functions must take two arguments:
"	JumpToBegin( count, isInner )
"	JumpToEnd( count, isInner )
"   a:count	Number of blocks to jump to. 
"   a:isInner	Flag whether the jump should be to the inner or outer delimiter
"		of the block. 
"   They should position the cursor to the appropriate position in the current
"   window. 
"
"* RETURN VALUES: 
"   None. 
"*******************************************************************************
    for l:type in split(a:types, '\zs')
	if l:type ==# 'a'
	    let l:isInner = 0
	elseif l:type ==# 'i'
	    let l:isInner = 1
	else
	    throw "ASSERT: Type must be either 'a' or 'i', but is: '" . l:type . "'! " 
	endif
	for l:mode in ['o', 'v']
	    execute escape(
	    \   printf("%snoremap <silent> %s %s :<C-U>call CountJump#TextObject#TextObjectWithJumpFunctions('%s', '%s', %s, %s)<CR>",
	    \   l:mode, a:mapArgs, (l:type . a:textObjectKey), l:isInner, a:selectionMode, string(a:JumpToBegin), string(a:JumpToEnd)
	    \   ), '|'
	    \)
	endfor
    endfor
endfunction

function! s:function(name)
    return function(substitute(a:name, '^s:', matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunction$'),''))
endfunction 
function! CountJump#TextObject#MakeWithCountSearch( mapArgs, textObjectKey, types, selectionMode, patternToBegin, patternToEnd )
"*******************************************************************************
"* PURPOSE:
"   Define a complete set of mappings for inner and/or outer text objects that
"   support an optional [count] and are driven by search patterns for the
"   beginning and end of a block. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"
"* EFFECTS / POSTCONDITIONS:
"   Creates mappings for operator-pending and visual mode which act upon /
"   select the text delimited by the begin and end patterns. 
"   If the pattern doesn't match (<count> times), a beep is emitted. 
"
"* INPUTS:
"   a:mapArgs	Arguments to the :map command, like '<buffer>' for a
"		buffer-local mapping. 
"   a:textObjectKey	Mapping key [sequence] after the mandatory i/a which
"			start the mapping for the text object. 
"   a:types		String containing 'i' for inner and 'a' for outer text
"			objects. 
"   a:selectionMode	Type of selection used between the patterns:
"			'v' for characterwise, 'V' for linewise, '<CTRL-V>' for
"			blockwise. 
"			In linewise mode, the inner text objects do not contain
"			the complete lines matching the pattern. 
"   a:patternToBegin	Search pattern to locate the beginning of a block. 
"   a:patternToEnd	Search pattern to locate the end of a block. 
"
"* RETURN VALUES: 
"   None. 
"*******************************************************************************
    let l:scope = (a:mapArgs =~# '<buffer>' ? 'b:' : 's:')

    " TODO: Escaping. Currently assuming that a:textObjectKey is a valid string
    " to be used in a function name. 
    let l:functionToBeginName = printf('%sJumpToBegin_%s', l:scope, a:textObjectKey)
    let l:functionToEndName   = printf('%sJumpToEnd_%s', l:scope, a:textObjectKey)

    execute printf("function! %s( count, isInner )\nreturn CountJump#CountSearch(a:count, ['%s', 'bW' . (a:isInner ? 'e' : '')])\nendfunction", l:functionToBeginName, s:Escape(a:patternToBegin))
    execute printf("function! %s( count, isInner )\nreturn CountJump#CountSearch(a:count, ['%s', 'W'  . (a:isInner ? '' : 'e')])\nendfunction", l:functionToEndName, s:Escape(a:patternToEnd))

    return CountJump#TextObject#MakeWithJumpFunctions(a:mapArgs, a:textObjectKey, a:types, a:selectionMode, s:function(l:functionToBeginName), s:function(l:functionToEndName))
endfunction

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
