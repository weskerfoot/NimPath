## API to allow for parsing HTML/XML and querying it using XPath expressions

Example code to query for anchors

```
for node in parseTree(client.getContent(base_url), "//a", base_url):
    var anchor_text = node.textContent
    if anchor_text.isSome:
        echo anchor_text.get
```

Querying subnodes, and reading from a file

```
var testFile = "./test.html".open(fmRead)
for node in parseTree(testFile.readAll, "//*[self::h1 or self::div]", "https://example.org"):
    for subnode in queryWithContext(node, "span"): # node is now the root to query from
        echo subnode.textContent.get
    if node.node.name == "h1":
        echo node.textContent.get
```

To install, simply add `https://github.com/weskerfoot/NimPath >= 0.1.3` to your .nimble file, and make sure clang is installed, and add `switch("passL", "/usr/lib/libxml2.so")` to config.nims in your project (or pass the linker flag manually).
