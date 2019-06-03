# Big Number Multiplication

input two numbers, then get their product.

## Windows version

Recommand building it in `Visual Studio`.

`big_multi_cmd.exe` should be run in command line, otherwise you might not be able to see the result.

`big_multi_window.exe` will be paused after the result was shown. 

## Linux version

If you are interested in building this version, try the command below.

```
; nasm required
; Using Linux and gcc:
; nasm -f elf multi.asm
; gcc -o multi multi.o driver.c asm_io.o -m32
```

