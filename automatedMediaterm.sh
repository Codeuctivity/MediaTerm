#!/bin/bash

#updated list avaliable videos
./mediaterm.sh -uq

#get all avaliable science busters episodes from orf servers (==apa.at)
./mediaterm.sh -sngow "Science Busters" | grep apa.at | grep SCIENCE-BUSTERS | while read line
do
	#download found file if there is no file with the same name in the destination folder
       	wget -nc $line -P ~/Videos/mediaterm/
done

