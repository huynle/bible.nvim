#!/bin/bash
cat ../books.txt | xargs -I@@ bash -c "bg2md -v NVB -c -l '@@' > '@@'.md"                                                                                                             │
