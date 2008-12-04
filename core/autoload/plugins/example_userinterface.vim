" using an external file because quoting can be annoing

map <buffer> <F8> :echo "hello world from cmd example"
command! -nargs=0 -buffer ExampleCmd echo "example cmd from cmd example"
