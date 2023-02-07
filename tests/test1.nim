import unittest, sequtils, nimpath, sugar
import std/encodings as encode

test "xpathQuery works with any element":
  var parsed = parseHTML("<html><body><h1>foobar</h1></body></html>", "")

  var nodes : seq[HTMLNode] = toSeq(xpathQuery(parsed, "//*"))

  assert map(nodes, (n) => n.node_name.get) == @["html", "body", "h1"]

  for node in xpathQuery(parsed, "//*"):
    if node.node_name.isSome and node.node_name.get == "h1":
      assert node.textContent.get == "foobar"

test "xpathQuery works with file":
  var testFile = "./test.html".open(fmRead)
  var parsed = parseHTML(testFile.readAll, "https://example.org")

  for node in xpathQuery(parsed, "//*[self::h1 or self::div]"):
    var subnode = getSingleWithContext(node, "span")
    if subnode.isSome:
      assert $subnode.get.textContent.get == "this is a span"
    if node.node.name == "h1":
      let expected_attrs = @[(name: "id", value: "some_id"), (name: "class", value: "header1")]
      let actual_attrs = toSeq(node.getAttributes)
      assert expected_attrs == actual_attrs
      assert node.textContent.get == "foo bar baz"

test "xpathQuery works with encoding":
  var nodecount : int = 0.int
  var testFile = "./test.html".open(fmRead)
  let conv = encode.open("utf-7", "ascii")
  let converted = encode.convert(conv, testFile.readAll)

  var parsed = parseHTML(converted, "https://example.org", encoding = some("utf-7"))

  for node in xpathQuery(parsed, "//*"):
    nodecount = nodecount + 1.int

  assert nodecount == 8
