
for drug in fentanyl hydrocodone oxycodone percocet morphine codeine
do
	COUNT=`grep -i ${drug} transcripts-export.csv  | wc -l`
	echo “$drug, ${COUNT}”
done

