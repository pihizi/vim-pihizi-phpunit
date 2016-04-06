if !executable('php')
    silent !sudo apt-get -y update
    silent !sudo apt-get -y install locales gettext php5-cli php5-curl php5-intl
endif

if !executable('phpunit')
    silent !sudo wget https://phar.phpunit.de/phpunit-old.phar
    silent !sudo mv phpunit-old.phar phpunit.phar
    " silent !sudo wget https://phar.phpunit.de/phpunit.phar
    silent !sudo chmod +x phpunit.phar
    silent !sudo mv phpunit.phar /usr/local/bin/phpunit
endif

" 
" binary file to run default
if !exists('g:phpunit_bin')
  let g:phpunit_bin = 'phpunit'
endif

"
" flags to run phpunit
if !exists('g:phpunit_params')
  let g:phpunit_params = '--stop-on-failure'
endif

if !exists('g:phpunit_highlights')
  highlight default PhpUnitFail ctermbg=Red ctermfg=White
  highlight default PhpUnitOK ctermbg=LightGreen ctermfg=White
  highlight default PhpUnitAssertFail ctermfg=LightRed
  let g:phpunit_highlights = 1
endif


"
" call shell with phpunit
"  $ <phpunit_bin> [[<phpunit_params>] <args>]
"
function! s:PHPUnitSystem(args)
  return system(g:phpunit_bin . ' ' . g:phpunit_params . ' ' . a:args)
endfunction

function! GetMyClassFile()
  let currentFileFullPath = expand('%:p')
  if match(currentFileFullPath, 'class\/Gini') != -1
      return currentFileFullPath
  endif

  let dirLists = split(expand('%:p'), '/')
  let testLists = []
  while !empty(dirLists)
      let tmpDir = dirLists[-1]
      if tmpDir!='tests' && tmpDir!='unit'
        let testLists = dirLists[-1:-1] + testLists
      endif
      let dirLists = dirLists[0:-2]
      let dirPath = '/' . join(dirLists, '/')
      let testFileFullPath = dirPath . '/class/Gini/' . join(testLists, '/')
      if filereadable(testFileFullPath)
          return testFileFullPath
      endif
  endwhile
endfunction

function! GetMyTestFile()
  let currentFileFullPath = expand('%:p')
  if match(currentFileFullPath, 'tests') != -1
      return currentFileFullPath
  endif

  let dirLists = split(expand('%:p'), '/')
  let testLists = []
  while !empty(dirLists)
      let tmpDir = dirLists[-1]
      if tmpDir!='class' && tmpDir!='Gini'
        let testLists = dirLists[-1:-1] + testLists
      endif
      let dirLists = dirLists[0:-2]
      let dirPath = '/' . join(dirLists, '/')
      let testFileFullPath = dirPath . '/tests/unit/' . join(testLists, '/')
      if filereadable(testFileFullPath)
          return testFileFullPath
      endif
      let testFileFullPath = dirPath . '/tests/' . join(testLists, '/')
      if filereadable(testFileFullPath)
          return testFileFullPath
      endif
  endwhile
endfunction

function! PHPUnitRun()
  let testFile = GetMyTestFile()
  if !filereadable(testFile)
    echo 'Test File for [' . expand('%:p') . '] not exists'
    return
  endif

  echohl Title
  echo "* Running PHP Unit test(s) [" . testFile . "] *"
  echohl None
  echo ""
  let phpunit_out = s:PHPUnitSystem(testFile)
  silent call <SID>PhpUnitOpenBuffer(phpunit_out)
endfunction

function! PHPUnitSwitch()
  if match(expand('%:p'), 'tests\/unit') != -1
      let file = GetMyClassFile()
      if !filereadable(file)
          echo 'Class File for [' . expand('%:p') . '] not exists'
          return
      endif
  else
      let file = GetMyTestFile()
      if !filereadable(file)
          echo 'Test File for [' . expand('%:p') . '] not exists'
          return
      endif
  endif
  execute 'to vsplit ' . file
endfunction

"
"render output to scratch buffer
"
function! s:PhpUnitOpenBuffer(content)
  " is there phpunit_buffer?
  if exists('g:phpunit_buffer') && bufexists(g:phpunit_buffer)
    let phpunit_win = bufwinnr(g:phpunit_buffer)
    " is buffer visible?
    if phpunit_win > 0
      " switch to visible phpunit buffer
      execute phpunit_win . "wincmd w"
    else
      " split current buffer, with phpunit_buffer
      execute "sb ".g:phpunit_buffer
    endif
    " well, phpunit_buffer is opened, clear content
    setlocal modifiable
    silent %d
  else
    " there is no phpunit_buffer create new one
    new
    let g:phpunit_buffer=bufnr('%')
  endif

  setlocal buftype=nofile modifiable bufhidden=hide
  silent put=a:content
  "efm=%E%\\d%\\+)\ %m,%CFailed%m,%Z%f:%l,%-G
  call matchadd("PhpUnitFail","^FAILURES.*$")
  call matchadd("PhpUnitOK","^OK .*$")
  call matchadd("PhpUnitAssertFail","^Failed asserting.*$")
  setlocal nomodifiable
endfunction

command! -nargs=0 -complete=file PHPUnit call PHPUnitRun()
command! -nargs=0 -complete=file PHPUnitSwitch call PHPUnitSwitch()

