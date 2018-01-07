#!/bin/bash
cd ~/MediaTerm/
#updated list avaliable videos
./mediaterm.sh -uq

#get all avaliable science busters episodes from orf servers (==apa.at)
./mediaterm.sh -sngow "Science Busters" | grep apa.at | grep SCIENCE-BUSTERS | while read line
do
	#download found file if there is no file with the same name in the destination folder
       	wget --limit-rate 600k -nc $line -P ~/Videos/mediaterm/
done

./mediaterm.sh -sngow "Kurzschluss - " | grep http | while read line
do
	
	IFS='|' read -a myarray <<< "$line"
        #download found file if there is no file with the same name in the destination folder
        echo downalodaing ${myarray[0]}
	wget --limit-rate 600k -nc ${myarray[0]} -P ~/Videos/mediaterm/Kurzschluss/
done

