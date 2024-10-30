#!/bin/bash

for file in {00001..99999}
do
	dd if=/dev/urandom of=/fsxn/randomdata/file-${file}.rnd bs=1k count=1 2>/dev/null
done
