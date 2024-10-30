

# grep -rlP 'title:' content/ | xargs -o -n1 sh -c 'aspell check "$@" --master=en_US --lang=en_US  --sug-mode=slow -x --mode=markdown < /dev/tty' whatever


# for f in **/*.md; do aspell check $f; done

find content -name index.en.md -exec aspell check {} \;


