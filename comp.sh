#!/bin/sh

#reading X
X=shell
echo "Enter X ammount."
read X
D=X * 0.7

#reading log
Y= du -s log |awk '{print $1}'
echo $Y

#main condition
if [$Y -le $D]
then
	#archiving
	tar -czf back.tar.gz log
	echo "/log archived"
	#removing files in log
	rm -r log/*
	#backup moving
	mv back.tar.gz backup
	echo "archive moved"
fi



