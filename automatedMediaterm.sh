#!/bin/bash
cd ~/MediaTerm/
PROBLEMLOGFILE="/home/htpc/mediaterm.log"
#updated list avaliable videos - if databse is older than one day
if test `find "filmliste" -mmin +1440`
then
    echo film list is older than one day - updating | tee -a "$PROBLEMLOGFILE"
    ./mediaterm.sh -uq | tee -a "$PROBLEMLOGFILE"
else
 echo film list is younger than one day | tee -a "$PROBLEMLOGFILE"
fi

#get all avaliable science busters episodes from orf servers (==apa.at)
./mediaterm.sh -sngow "Science Busters" | grep apa.at | grep SCIENCE-BUSTERS | while read line
do
	#download found file if there is no file with the same name in the destination folder
        echo downloding $line | tee -a "$PROBLEMLOGFILE"
       	wget -c --limit-rate 600k $line -P ~/Videos/mediaterm/  | tee -a "$PROBLEMLOGFILE"
        echo downloding $line done | tee -a "$PROBLEMLOGFILE"
done

./mediaterm.sh -sngow "Kurzschluss - " | grep http | while read line
do
	IFS='|' read -a myarray <<< "$line"
        #download found file if there is no file with the same name in the destination folder
        echo downloding ${myarray[0]} | tee -a "$PROBLEMLOGFILE"
	wget -c --limit-rate 600k ${myarray[0]} -P ~/Videos/mediaterm/Kurzschluss/ | tee -a "$PROBLEMLOGFILE"
	echo downloding ${myarray[0]} done | tee -a "$PROBLEMLOGFILE"
done

