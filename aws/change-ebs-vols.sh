
# Simple script to modify  a SGW volumes from GP3 to IO2.  I had to manually add the vols to a text input file because I
# am a true slacker.  
for vol in `cat vols.txt`
do
    # echo aws ec2 modify-volume --volume-id $vol --volume-type io2 
    echo aws ec2 modify-volume --volume-id $vol --volume-type io2 --iops=5000 
    # echo aws ec2 describe-volume-status --volume-ids $vol
done
