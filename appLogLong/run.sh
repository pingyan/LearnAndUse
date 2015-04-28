#!/bin/usr/sh


for d in {25..26}
do 
	perl getlogLong.pl 04 $d

	sleep 60m

	dir=/Users/pyan/ping/experiments/appLogLong/data

	cd $dir 
	logfn=$(find . -cmin -60 | tail -1) 

	python /Users/pyan/ping/LogDeepDive/misc/logfilter_splunk.py $logfn $dir /Users/pyan/ping/LogDeepDive/misc/196.conf.clean

	rm $logfn

done

