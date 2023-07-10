import system, strformat, strutils

const clangResourceDir = staticExec("clang -print-resource-dir").strip

switch("passL", staticExec("pkg-config --libs libxml-2.0").strip)
switch("d", fmt"clangResourceDir={clangResourceDir}")
