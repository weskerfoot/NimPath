# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import nimpath

test "parseTree works":
  for node in parseTree("<html><body><h1>foobar</h1></body></html>", "//*", ""):
    echo $node

test "parseTree works":
  var testFile = "./test.html".open(fmRead)
  for node in parseTree(testFile.readAll, "//*[self::h1 or self::div]", "https://example.org"):
    var subnode = getSingleWithContext(node, "span")
    if subnode.isSome:
      echo $subnode.get.textContent
    if node.node.name == "h1":
      echo node.textContent.get
