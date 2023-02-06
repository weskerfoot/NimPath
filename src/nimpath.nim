import system, strutils, sequtils, tables, strformat, options, futhark, locks
export options

const clangResourceDir {.strdefine.}: string = staticExec("clang -print-resource-dir").strip
importc:
  sysPath fmt"{clangResourceDir}/include"
  path: "/usr/include/libxml2/libxml"
  path: "/usr/include/libxml2"
  "parser.h"
  "xpath.h"
  "xpathInternals.h"
  "tree.h"
  "HTMLparser.h"

var parserLock : Lock
parserLock.initLock()

proc cstringToNim(cst : cstring) : Option[string] =
  var nst = newString(cst.len)
  if nst.len > 0:
    copyMem(addr(nst[0]), cst, cst.len)
    return some(nst)
  none(string)

type HTMLNode* = ref object of RootObj
  node_name*: Option[string]
  node*: ptr xmlNode
  context*: xmlXPathContextPtr

proc textContent*(node: HTMLNode): Option[string] =
  return cast[cstring](node.node.xmlNodeGetContent).cstringToNim

iterator getAttributes*(node: HTMLNode): tuple[name: string, value: string] =
  var current_attr: ptr structxmlattr = node.node.properties
  while current_attr != nil:
    var value = cast[cstring](xmlNodeListGetString(node.node.doc, current_attr.children, 1))
    yield (current_attr.name.cstringToNim.get, value.cstringToNim.get)
    xmlFree(value)
    current_attr = current_attr.next

proc `$`* (node: HTMLNode): string =
  $node.node[]

iterator query*(xpath_expr: string, xpath_ctx : xmlXPathContextPtr): HTMLNode =
  var xpath_obj : xmlXPathObjectPtr = xmlXPathEvalExpression(cast[ptr xmlChar](xpath_expr.cstring), xpath_ctx);
  var nodes : xmlNodeSetPtr = xpath_obj.nodesetval;

  var currentNode : ptr xmlNodePtr = nodes.nodeTab

  if nodes.nodeNr > 0:
    for i in (0..(nodes.nodeNr-1)):
      currentNode = cast[ptr xmlNodePtr](cast[int](nodes.nodeTab) + cast[int](i * nodes.nodeTab.sizeof))
      yield HTMLNode(node_name: cstringToNim(currentNode[].name), node: currentNode[], context: xpath_ctx)

iterator queryWithContext*(node: HTMLNode, xpath_expr: string) : HTMLNode =
  discard xmlXPathSetContextNode(node.node, node.context)
  for node in query(xpath_expr, node.context):
    yield node

template getSingleWithContext*(node: HTMLNode, xpath_expr: string): Option[HTMLNode] =
  block:
    var results = toSeq(queryWithContext(node, xpath_expr))
    if len(results) == 0:
      none(HTMLNode)
    else:
      some(results[0])

iterator parseTree*(input: string,
                    xpath_expr: string,
                    base_url: string,
                    locked : bool = true,
                    encoding : Option[string] = none(string)) : HTMLNode =
  if locked:
    parserLock.acquire()
  var input_p : cstring = input.cstring
  var input_p_size : cint = input_p.len.cint
  var base_url : cstring = base_url.cstring
  var encoding : cstring = if encoding.isNone: nil else: encoding.get.cstring
  var options : cint = (XML_PARSE_RECOVER.int or XML_PARSE_NOWARNING.int or XML_PARSE_HUGE.int or XML_PARSE_NONET.int).cint

  var parser_result : xmlDocPtr = htmlReadMemory(input_p, input_p_size, base_url, encoding, options)

  var xpath_ctx : xmlXPathContextPtr = xmlXPathNewContext(parser_result)

  if (xpath_ctx == nil):
    xpath_ctx.xmlXPathFreeContext
    parser_result.xmlFreeDoc

  for node in query(xpath_expr, xpath_ctx):
    yield node

  xpath_ctx.xmlXPathFreeContext
  parser_result.xmlFreeDoc

  xmlCleanupParser()
  if locked:
    parserLock.release()
