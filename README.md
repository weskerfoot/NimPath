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
