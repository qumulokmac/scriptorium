
###
# Yes, this is a hack. bite me
###

awk '/RD\=format_for_qumulo_readwrite_iops/{p++;if(p==1){next}}p' summary.html | awk '/For loops\: operation=read/{p++;if(p==1){next}}p' | awk '/operation\=write/{stop=1} stop==0{print}' | sed '/^[[:space:]]*$/d' | sed '/Interval/d' | sed '/rate/d' | sed '/avg/d' | sed '/std/d' | sed '/max/d' | sed '/Vdbench/d' | tr -s ' ' | sed 's/ /,/g'  > read.csv

# Verified write
awk '/RD\=format_for_qumulo_readwrite_iops/{p++;if(p==1){next}}p' summary.html | awk '/For loops\: operation=write/{p++;if(p==1){next}}p' | sed '/^[[:space:]]*$/d' | sed '/Interval/d' | sed '/rate/d' | sed '/avg/d' | sed '/std/d' | sed '/max/d' | sed '/Vdbench/d' | tr -s ' ' | sed 's/ /,/g'  > write.csv
