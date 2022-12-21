import nimpathpkg/parser
export parser

when isMainModule:
  var testFile = "./test.html".open(fmRead)
  for node in parseTree(testFile.readAll, "//*[self::h1 or self::div]"):
    for subnode in queryWithContext(node, "span"):
      echo subnode.textContent.get
    if node.node.name == "h1":
      echo node.textContent.get
