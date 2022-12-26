import nimpathpkg/parser
export parser

when isMainModule:
  var testFile = "./test.html".open(fmRead)
  for node in parseTree(testFile.readAll, "//*[self::h1 or self::div]", "https://example.org"):
    var subnode = getSingleWithContext(node, "span")
    if subnode.isSome:
      echo $subnode.get.textContent
    if node.node.name == "h1":
      echo node.textContent.get
