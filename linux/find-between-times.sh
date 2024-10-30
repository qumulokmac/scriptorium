
 touch -t 202405080000 /tmp/start
 touch -t 202405092359 /tmp/end
 find . -type f -newer /tmp/start ! -newer /tmp/end
