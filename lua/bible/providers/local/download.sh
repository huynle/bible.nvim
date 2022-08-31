#!/bin/bash
cat ../books.txt | xargs -I@@ bash -c "bg2md -v NABRE -c -l '@@' > '@@'.md"                                                                                                             │
