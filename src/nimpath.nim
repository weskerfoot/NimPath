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

proc `$`*(cst : ptr xmlChar) : string {.inline.} =
  result = $cast[cstring](cst)

func stringOpt(s: sink string): Option[string] =
  ## Returns `None` if s is empty
  if s.len > 0: 
    result = some s

type HTMLNode* = ref object of RootObj
  node_name*: Option[string]
  node*: ptr xmlNode
  context*: xmlXPathContextPtr

type XMLDoc* = object
  doc: xmlDocPtr

proc `=destroy`(doc: var XMLDoc) =
  doc.doc.xmlFree()

proc textContent*(node: HTMLNode): Option[string] =
  stringOpt $node.node.xmlNodeGetContent

iterator getAttributes*(node: HTMLNode): tuple[name: string, value: string] =
  var current_attr: ptr structxmlattr = node.node.properties
  while current_attr != nil:
    var value = cast[cstring](xmlNodeListGetString(node.node.doc, current_attr.children, 1))
    yield ($current_attr.name, $value)
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
      yield HTMLNode(node_name: stringOpt $currentNode[].name, node: currentNode[], context: xpath_ctx)
  xmlFree xpath_obj
 
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

# TODO allow to pass options
proc parseHTML*(input : string, base_url: string, encoding: Option[string] = none(string)) : XMLDoc =
  var input_p : cstring = input.cstring
  var input_p_size : cint = input_p.len.cint
  var base_url : cstring = base_url.cstring
  var encoding : cstring = if encoding.isNone: nil else: encoding.get.cstring
  var options : cint = (XML_PARSE_RECOVER.int or XML_PARSE_NOWARNING.int or XML_PARSE_HUGE.int or XML_PARSE_NONET.int).cint
  XMLDoc(doc: htmlReadMemory(input_p, input_p_size, base_url, encoding, options))

iterator xpathQuery*(input: XMLDoc,
                     xpath_expr: string,
                     locked : bool = true) : HTMLNode =
  if locked:
    parserLock.acquire()

  var xpath_ctx : xmlXPathContextPtr = xmlXPathNewContext(input.doc)

  if (xpath_ctx == nil):
    xpath_ctx.xmlXPathFreeContext

  for node in query(xpath_expr, xpath_ctx):
    yield node

  xpath_ctx.xmlXPathFreeContext

  xmlCleanupParser()
  if locked:
    parserLock.release()
