import system, strutils, termios, posix, bitops, sequtils, tables, strformat, options, futhark

const clangResourceDir {.strdefine.}: string = "nothing" # defined by config.nims
importc:
  sysPath fmt"{clangResourceDir}/include"
  path: "/usr/include/libxml2/libxml"
  path: "/usr/include/libxml2"
  "parser.h"
  "xpath.h"
  "xpathInternals.h"
  "tree.h"

proc cstringToNim(cst : cstring) : Option[string] =
  var nst = newString(cst.len)
  if nst.len > 0:
    copyMem(addr(nst[0]), cst, cst.len)
    return some(nst)
  none(string)

type HTMLNode = ref object of RootObj
  node*: xmlNode
  context*: xmlXPathContextPtr

proc textContent*(node: HTMLNode): Option[string] =
  return node.node.addr.xmlNodeGetContent.cstringToNim

proc `$` (node: HTMLNode): string =
  "node"

iterator query*(xpath_expr: string, xpath_ctx : xmlXPathContextPtr): HTMLNode =
  var xpath_obj : xmlXPathObjectPtr = xmlXPathEvalExpression(cast[ptr xmlChar](xpath_expr.cstring), xpath_ctx);
  var nodes : xmlNodeSetPtr = xpath_obj.nodesetval;

  var currentNode : ptr xmlNodePtr = nodes.nodeTab

  for i in (0..(nodes.nodeNr-1)):
    currentNode = cast[ptr xmlNodePtr](cast[int](nodes.nodeTab) + cast[int](i * nodes.nodeTab.sizeof))
    #echo currentNode[].name, ", ", currentNode[].xmlNodeGetContent
    yield HTMLNode(node: currentNode[][], context: xpath_ctx)

iterator queryWithContext*(node: HTMLNode, xpath_expr: string) : HTMLNode =
  var oldContext = node.context[]
  discard xmlXPathSetContextNode(node.node.addr, node.context)
  for node in query(xpath_expr, node.context):
    yield node

  node.context = oldContext.addr

iterator parseTree*(input: string, xpath_expr: string) : HTMLNode =
  var input_p : cstring = input.cstring
  var input_p_size : cint = input_p.len.cint
  var base_url : cstring = "https://example.org".cstring # TODO pass as parameter
  var encoding : cstring = nil # TODO, different encodings?
  var options : cint = (XML_PARSE_RECOVER.int or XML_PARSE_NOWARNING.int or XML_PARSE_HUGE.int or XML_PARSE_NONET.int).cint

  var parser_result : xmlDocPtr = xmlReadMemory(input_p, input_p_size, base_url, encoding, options)

  var xpath_ctx : xmlXPathContextPtr = xmlXPathNewContext(parser_result)

  if (xpath_ctx == nil):
    xpath_ctx.xmlXPathFreeContext
    parser_result.xmlFreeDoc
    #return # TODO raise exceptions
    #
  for node in query(xpath_expr, xpath_ctx):
    yield node

  xpath_ctx.xmlXPathFreeContext
  parser_result.xmlFreeDoc

  #xmlInitParser()

  #xmlCleanupParser()
  #xmlMemoryDump()
