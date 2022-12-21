import nimpathpkg/parser

when isMainModule:
  for node in parseTree("<html><body><h1>foobar</h1><h2>sdasdasd</h2><h1><p>this is a p</p><p>this is another p</p></h1></body></html>", "//*[self::h1 or self::h2]"):
    for subnode in queryWithContext(node, "p"):
      echo subnode.textContent
