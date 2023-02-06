import unittest, sequtils, nimpath, sugar
import std/encodings as encode

test "parseTree works with any element":
  var nodes : seq[HTMLNode] = toSeq(parseTree("<html><body><h1>foobar</h1></body></html>", "//*", ""))
  assert map(nodes, (n) => n.node_name.get) == @["html", "body", "h1"]
  for node in parseTree("<html><body><h1>foobar</h1></body></html>", "//*", ""):
    if node.node_name.isSome and node.node_name.get == "h1":
      assert node.textContent.get == "foobar"

test "parseTree works with file":
  var testFile = "./test.html".open(fmRead)
  for node in parseTree(testFile.readAll, "//*[self::h1 or self::div]", "https://example.org"):
    var subnode = getSingleWithContext(node, "span")
    if subnode.isSome:
      echo $subnode.get.textContent
    if node.node.name == "h1":
      let expected_attrs = @[(name: "id", value: "some_id"), (name: "class", value: "header1")]
      let actual_attrs = toSeq(node.getAttributes)
      assert expected_attrs == actual_attrs
      assert node.textContent.get == "foo bar baz"

test "parseTree works with encoding":
  var nodecount : int = 0.int
  var testFile = "./test.html".open(fmRead)
  let conv = encode.open("utf-7", "ascii")
  let converted = encode.convert(conv, testFile.readAll)

  for node in parseTree(converted, "//*", "https://example.org", encoding = some("utf-7")):
    nodecount = nodecount + 1.int

  assert nodecount == 8
