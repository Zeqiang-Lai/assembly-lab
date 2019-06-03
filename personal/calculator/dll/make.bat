@echo off
if exist ExprEvaluator.obj del ExprEvaluator.obj
if exist ExprEvaluator.dll del ExprEvaluator.dll
ml /c /coff ExprEvaluator.asm
link /SUBSYSTEM:WINDOWS /DLL /DEF:ExprEvaluator.def ExprEvaluator.obj 
del ExprEvaluator.exp
dir ExprEvaluator.*
pause