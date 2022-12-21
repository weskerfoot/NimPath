import system, strformat, strutils

const clangResourceDir = staticExec("clang -print-resource-dir").strip

switch("passL", "/usr/lib/libxml2.so")
switch("d", fmt"clangResourceDir={clangResourceDir}")
