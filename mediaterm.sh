

#!/bin/bash

# Mit dem Bash-Skript MediaTerm lassen sich Filme aus den Mediatheken
# der öffentlich-rechtlichen Fernsehsender ressourcenschonend im
# Linux-Terminal suchen, abspielen, herunterladen und als Bookmarks
# speichern. MediaTerm greift dabei auf die Filmliste des Programms
# MediathekView (https://mediathekview.de/) zurück.

# http://martikel.bplaced.net/skripte1/mediaterm.html

#################################################################
#
#  Copyright (c) 2017 Martin O'Connor (mar.oco@arcor.de)
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see http://www.gnu.org/licenses/.
#
################################################################

#### Vorbelegte Variablen

dir=$HOME/MediaTerm   #Verzeichnis, in dem Filmliste und Bookmarks gespeichert werden
dldir=$PWD   #Zielverzeichnis für den Download von Videos (aktuelles Arbeitsverzeichnis ... bei Bedarf ändern)

player="mpv --really-quiet --no-ytdl"   #Player mpv mit Optionen

datum1=01.01.0000   #fiktive untere Zeitgrenze bei Nichtnutzung der Option -d
datum2=31.12.9999   #fiktive obere Zeitgrenze bei Nichtnutzung der Option -e

#### OPTIONEN

while getopts ":bd:e:ghHlnostuvw" opt; do
    case $opt in
        b)
            bopt=1
            ;;
        d)
            datum1=$(echo "$OPTARG" | awk -F "." 'NF==3{print $3"."$2"."$1}; NF==2{print $2"."$1.".01"}; NF==1{print $1".01.01"}')   #Datum wird invertiert: tt.mm.jjjj -> jjjj.mm.tt

            ;;
        e)
            datum2=$(echo "$OPTARG" | awk -F "." 'NF==3{print $3"."$2"."$1}; NF==2{print $2"."$1".31"}; NF==1{print $1"12.31"}')   #Datum wird invertiert: tt.mm.jjjj -> jjjj.mm.tt
            ;;
        g)
            gopt=1
            ;;
        h)
            hopt=1
            ;;
        l)
            lopt=1
            player="mpv --really-quiet --ytdl"
            ;;
        n)
            nopt=1
            ;;
        o)
            oopt=1
            ;;
        s)
            sopt=1
            ;;
        t)
            topt=1
            ;;
        u)
            uopt=1
            ;;
        v)
            if [ ! -f $dir/filmliste ]; then
                flstand="Datei \"filmliste\" nicht gefunden"
            else
                flstand=$(head -n +1 $dir/filmliste | cut -d"\"" -f6)
            fi
            echo "MediaTerm 6.3.2, 2017-08-25 (Stand der Filmliste: $flstand)"
            exit
            ;;
        w)
            wopt=1
            ;;
        H)
            Hopt=1   #undokumentierte interne Option, um Ausführung von Suchen auf der internen Kommandozeile zu markieren
            ;;
        \?)
            echo "Ungültige Option: -$OPTARG" >&2
            exit
            ;;
    esac
done

#Variable für Anzeige der Suchanfrage unterhalb der Trefferliste
if [ ! -z $Hopt ]; then
    suchanfrage=$(for i in "${@:2}"; do echo -n " $i"; done)   #"versteckte" Option -H soll nicht angezeigt werden
else
    suchanfrage=$(for i in "${@}"; do echo -n " $i"; done)
fi

shift $(($OPTIND -1))

if [[ -z $1 && ! -z $nopt && -z $lopt ]]; then
      echo "Es wurde kein Suchwort eingegeben (bei Option -n erforderlich)."
      exit
fi

#---------------------------------------------------------------
# Hilfe
#---------------------------------------------------------------
fett=$(tput bold)
normal=$(tput sgr0)
unterstr=$(tput smul)

if [ ! -z $hopt ]; then

# Zeige den folgenden Textblock an

    fmt -s -w $(tput cols) << ende-hilfetext

Mit MediaTerm können im Terminal Filme aus den Mediatheken der öffentlich-rechtlichen Fernsehsender gesucht, mit dem Medienplayer mpv abgespielt sowie heruntergeladen werden.

${fett}VORAUSSETZUNGEN FUER DAS FUNKTIONIEREN DES SKRIPTS:${normal}
      curl, mpv, xz-utils und wahlweise ffmpeg oder libav-tools müssen installiert sein.
      Empfohlen wird außerdem youtube-dl in einer aktuellen Version. 

${fett}AUFRUF:${normal}
      mediaterm [-d DATUM|-e DATUM|-g|-n|-o|-s|-t|-w] [+]Suchstring1 [[+|~]Suchstring2 ...]
      mediaterm -l[n|o|w]
      mediaterm -b
      mediaterm -u
      mediaterm -v
      mediaterm -h

      "mediaterm" ohne Optionen oder Argumente ausgeführt öffnet die Eingabezeile von MediaTerm. Auf ihr werden Suchanfragen nach obigem Muster OHNE einleitende Angabe des Befehls "mediaterm" ausgeführt.

${fett}OPTIONEN:${normal}
      ${fett}-b${normal}   Anzeige, Abspielen und Löschen der Bookmarks.
      ${fett}-d DATUM${normal}   Sucht nur Sendungen neuer als DATUM (und vom DATUM); DATUM muss im Format [[TT.]MM.]JJJJ eingegeben werden.
      ${fett}-e DATUM${normal}   Sucht nur Sendungen älter als DATUM (und vom DATUM); DATUM muss im Format [[TT.]MM.]JJJJ eingegeben werden.
      ${fett}-g${normal}   Unterscheidet bei der Suche zwischen Groß- und Kleinbuchstaben.
      ${fett}-h${normal}   Zeigt diese Hilfe an.
      ${fett}-l${normal}   Listet alle Livestreams auf (Suchstrings werden nicht berücksichtigt).
      ${fett}-n${normal}   Gibt die Ergebnisliste ohne interne Kommandozeile aus.
      ${fett}-o${normal}   Gibt die Ergebnisliste ohne Farben aus.
      ${fett}-s${normal}   Sortiert Suchtreffer absteigend nach Sendedatum (neueste zuoberst).
      ${fett}-t${normal}   Sortiert Suchtreffer aufsteigend nach Sendedatum (neueste zuunterst).
      ${fett}-u${normal}   Aktualisiert die Filmliste.
      ${fett}-v${normal}   Zeigt die MediaTerm-Version und das Erstellungsdatum der Filmliste.
      ${fett}-w${normal}   Deaktiviert die worterhaltenden Zeilenumbrüche in der Ergebnisliste.

${fett}SUCH-OPERATOREN:${normal}
       ${fett}+${normal}   Ein "+" unmittelbar vor einem Suchstring bewirkt, dass dieser als Einzelwort gesucht wird und NICHT als Zeichenfolge auch innerhalb von Wörtern.
       ${fett}~${normal}   Eine Tilde (~) unmittelbar vor einem Suchstring schließt diesen für die Suche gezielt aus. Dieser Operator kann nicht mit dem ersten Suchstring verwendet werden.

${fett}ANWENDUNGSBEISPIELE:${normal}
   ${unterstr}mediaterm alpen klimawandel${normal}
      ... listet alle Filme auf, in deren Titel, Beschreibung oder URL die Zeichenfolgen "alpen" und "klimawandel" vorkommen (unabhängig von Groß-/Kleinschreibung). Die gefundenen Filme können per Eingabe der jeweiligen Treffernummer gestreamt, heruntergeladen oder als Bookmark gespeichert werden.

   ${unterstr}mediaterm -now alpen klimawandel${normal}
      ... liefert die gleiche Trefferliste in roher Form, d.h. ohne Kommandoeingabe (-n), ohne Farbe (-o) und ohne worterhaltende Zeilenumbrüche (-w). Dies ist beispielsweise sinnvoll, wenn die Liste weiterverarbeitet oder in eine Datei umgeleitet werden soll.

   ${unterstr}mediaterm +gier${normal}
      ... sucht nur nach Treffern, in denen "gier" bzw. "Gier" als ganzes Wort vorkommt; beispielsweise bleiben "gierig", "Magier" oder "Passagiere" unberücksichtigt.

   ${unterstr}mediaterm -d 15.05.2015 -e 2016 alpen klimawandel${normal}
      ... beschränkt die Suche auf Sendungen aus dem Zeitraum 15.05.2015-31.12.2016.

   ${unterstr}mediaterm python ~monty${normal}
      ... vermindert die Ergebnismenge der Suche nach "python" um alle Treffer, in denen die Zeichenfolge "monty" vorkommt.
ende-hilfetext

# Falls Hilfe aus der internen Kommandozeile aufgerufen, kein "exit"
    if [ -z $Hopt ]; then
        exit 0
    fi
fi

#---------------------------------------------------------------

#### FUNKTIONEN hits, icli, bmcomm, bmcli, urlqual, pageview

# Definition der FUNKTION hits: Formatierung und Ausgabe der Suchergebnisse
function hits {

      # Meldung bei leerer Treffermenge
      if [[ ! $out  ]]; then
          if [ ! -z $oopt ]; then
              printf "\033[1mZu der Suche wurden leider keine Treffer gefunden.\033[0m\n"
          else
              printf "\033[0;31mZu der Suche wurden leider keine Treffer gefunden.\033[0m\n"
          fi
          #Bei leerer Treffermenge Anwendung nur beenden, wenn Suchanfrage auf der Kommandozeile (Terminal) ausgeführt wurde.
          if [[ -z $Hopt && "$suchanfrage" != " Bookmark $input" ]]; then
              exit
          fi
      fi

    # Kompakte Ausgabe der Ergebnisliste Livestreams
    if [ ! -z $lopt ]; then
        echo "$out" | \
            awk -F "\",\"" '{print "("NR")", "\033[0;32m"$4"\033[0m"" ("$1")", "\n" "\033[0;34m"$10"\033[0m","\n"}' | \
            ( if [ ! -z $oopt ]; then sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"; else tee; fi ) |   #Entfernt Farbformatierungen bei Option -o \
            ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )   #Worterhaltende Zeilenumbrüche (außer bei Option -w)

    # Detaillierte Ausgabe der übrigen Ergebnislisten
    elif [[ ! -z $out ]]; then
        echo "$out" | \
            awk -F "\",\"" '{ORS=" "}; {print "("NR")", "\033[0;32m"$4"\033[0m"" ("$1": "$3")"}; {if($14!=""){printf "[n"} else{printf "[-"}}; {if($16!=""){print "/h]"} else{print "/-]"}}; {print "\n"  "\33[1m""Datum:""\033[0m",$5  ",",  $6,"Uhr","*",  "\33[1m""Dauer:""\033[0m",  $7,"\n" $9,  "\n" "\033[0;34m"$10"\033[0m"} {printf "\n\n"}' | \
            ( if [ ! -z $oopt ]; then sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"; else tee; fi ) |   #Entfernt Farbformatierungen bei Option -o \
            tr -d '\\' |   #Entfernt Escape-Backslashes aus Ausgabe \
            ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )   #Worterhaltende Zeilenumbrüche (außer bei Option -w)
    fi

echo "[Suchanfrage:$suchanfrage]" #Anzeige der Suchanfrage unter der Trefferliste

    # Bei Option -n nach Ausgabe der Trefferliste exit
    if [ ! -z $nopt ]; then
        exit 0
    fi
}

# Definition der FUNKTION icli: Interne Kommandozeile
function icli {
trefferzahl=$(echo "$out" | wc -l) #Anzahl der Treffer (= Zeilen von $out)
if [[ -z $out ]]; then
    trefferzahl=0
fi

printf '%.0s-' $(seq $(tput cols)); printf '\n'   #gestrichelte Trennlinie
if [[ ! $out ]]; then
    printf "\033[1mNach Fernsehsendungen suchen ...\033[0m\n\033[1mH\033[0m zeigt die Hilfe zur Suche; \033[1mq\033[0m beendet mediaterm; \033[1mk\033[0m listet zusätzliche Kommando-Optionen auf.\n"
else
    printf "\033[1mZum Abspielen Nummer des gewünschten Films eingeben (... oder neue Suche starten)\033[0m \n\033[1mq\033[0m beendet mediaterm. \033[1mk\033[0m zeigt zusätzliche Kommando-Optionen.\n" | ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )
fi

while [ 1 ]; do
    # Benutzereingabe der Treffernummer bzw. eines Kommandos
    read -e -p "> " input
    history -s -- "$input"

    # Auflistung zusätzlicher Kommando-Optionen bei Kommando k
    if [[ "$input" == "k" ]]; then
        printf " \033[1mh\033[0m voranstellen, um Film in hoher Qualität abzuspielen (z.B. h6),\n \033[1mn\033[0m voranstellen, um Film in niedriger Qualität abzuspielen (z.B. n9),\n(zur Verfügbarkeit niedriger/hoher Qualität siehe Kennzeichnung [n/h] hinter Filmtitel)\n \033[1mb\033[0m voranstellen, um Bookmark zu speichern (z.B. b4),\n \033[1md\033[0m voranstellen, um Film in Standardqualität herunterzuladen (z.B. d17),\n \033[1mdh\033[0m voranstellen, um Film in hoher Qualität herunterzuladen (z.B. dh1),\n \033[1mdn\033[0m voranstellen, um Film in niedriger Qualität herunterzuladen (z.B. dn2),\n \033[1mw\033[0m voranstellen, um Internetseite zur Sendung im Browser zu öffnen (z.B. w35),\n \033[1mi\033[0m voranstellen, um alle zum Film gehörenden Links anzuzeigen (z.B. i2),\n \033[1ma\033[0m (\033[1mA\033[0m) voranstellen, um nur 5 (10) Treffer ab Filmnr. anzuzeigen (z.B. a10 bzw. A10),\n(\033[1ma\033[0m bzw. \033[1mA\033[0m ohne Nummer entspricht a1 bzw. A1)\n \033[1m+\033[0m (oder \033[1mv\033[0m) blättert vorwärts (in Teilansicht mit 5 bzw. 10 Treffern),\n \033[1m-\033[0m (oder \033[1mr\033[0m) blättert rückwärts (in Teilansicht mit 5 bzw. 10 Treffern),\n \033[1mz\033[0m liest die Trefferliste neu ein,\n \033[1mB\033[0m wechselt in den Modus \"Bookmarks\" (Ansicht, Abspielen, Löschen),\n \033[1mH\033[0m zeigt die Hilfe zur Filmsuche.\n"

    elif [[ "$input" = "q" || "$input" = "quit" || "$input" = "exit" ]]; then
        exit   #Beenden des Programs bei Eingabe von "q", "quit" oder "exit"

    elif [[ "$input" = "B" ]]; then
        if [ ! -f $dir/bookmarks ]; then
            echo "Die Datei $dir/bookmarks existiert nicht."
        else
            bmcli   #Wechsel zur Kommandozeile Bookmarks
        fi
    
    elif [[ "$input" = "H" ]]; then

#----- Zeige den folgenden Textblock an (Suchhilfe): -----
fett=$(tput bold)
normal=$(tput sgr0)
unterstr=$(tput smul)

fmt -s -w $(tput cols) << ende-hilfe

                    ${fett}*** HILFE zur Filmsuche ***${normal}

${fett}OPTIONEN:${normal}
      ${fett}-d DATUM${normal}   Sucht nur Sendungen neuer als DATUM (und vom DATUM); DATUM muss im Format [[TT.]MM.]JJJJ eingegeben werden.
      ${fett}-e DATUM${normal}   Sucht nur Sendungen älter als DATUM (und vom DATUM); DATUM muss im Format [[TT.]MM.]JJJJ eingegeben werden.
      ${fett}-g${normal}   Unterscheidet bei der Suche zwischen Groß- und Kleinbuchstaben.
      ${fett}-h${normal}   Zeigt die ausführliche Hilfe an.
      ${fett}-l${normal}   Listet alle Livestreams auf (Suchstrings werden nicht berücksichtigt).
      ${fett}-s${normal}   Sortiert Suchtreffer absteigend nach Sendedatum (neueste zuoberst).
      ${fett}-t${normal}   Sortiert Suchtreffer aufsteigend nach Sendedatum (neueste zuunterst).

${fett}SUCH-OPERATOREN:${normal}
       ${fett}+${normal}   Ein "+" unmittelbar vor einem Suchstring bewirkt, dass dieser als Einzelwort gesucht wird und NICHT als Zeichenfolge auch innerhalb von Wörtern.
       ${fett}~${normal}   Eine Tilde (~) unmittelbar vor einem Suchstring schließt diesen für die Suche gezielt aus. Dieser Operator kann nicht mit dem ersten Suchstring verwendet werden.

${fett}SUCHBEISPIEL:${normal}
      ${unterstr}-gt +EU Gurke${normal}
            ... sucht nach Einträgen mit dem Einzelwort "EU" (exakte Wortsuche mit +) und dem Wort(teil) "Gurke". Dabei wird zwischen Groß- und Kleinschreibung unterschieden (-g), und die Treffer werden aufsteigend nach Sendedatum sortiert ausgegeben (-t).
ende-hilfe
#----- Ende Textblock ------
          icli

    elif [[ "$input" =~ ^a[0-9]?+$ ]]; then   #Anzeige von 5 Treffern ab Zeile ...
        if [[ $trefferzahl -lt 5 ]]; then
            echo "Kommando wird bei weniger als 5 Treffern nicht unterstützt!"
        else 
            a=$(echo ${input//[!0-9]/})
            let a=$(( a < trefferzahl ? a : trefferzahl-4 ))
            let a=$(( a > 0 ? a : 1 ))
            let x=(a-1)*5+1
            let y=x+24
            pl=5
            pageview
            icli
        fi

    elif [[ "$input" =~ ^A[0-9]?+$ ]]; then   #Anzeige von 10 Treffern ab Zeile ...
        if [[ $trefferzahl -lt 10 ]]; then
            echo "Kommando wird bei weniger als 10 Treffern nicht unterstützt!"
        else
            a=$(echo ${input//[!0-9]/})
            let a=$(( a < trefferzahl ? a : trefferzahl-9 ))
            let a=$(( a > 0 ? a : 1 ))
            let x=(a-1)*5+1
            let y=x+49
            pl=10
            pageview
            icli
        fi

    elif [[ "$input" = "v" || "$input" = "+" ]]; then   #Blättern vorwärts
        if [[ "$a" = "" ]]; then
            echo "Blättern ist in der Gesamtansicht der Trefferliste nicht möglich. Bitte zuerst mit Kommando a oder A zu einem Eintrag springen." | ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )
        else
            let a=$(( a+pl <= trefferzahl ? a+pl : a ))
            let x=(a-1)*5+1
            let y=x+pl*5-1
            pageview
            icli
        fi

    elif [[ "$input" = "r" || "$input" = "-" ]]; then   #Blättern rückwärts
        if [[ "$a" = "" ]]; then
            echo "Blättern ist in der Gesamtansicht der Trefferliste nicht möglich. Bitte zuerst mit Kommando a oder A zu einem Eintrag springen." | ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )
        else
            let a=$(( a-pl > 0 ? a-pl : 1 ))
            let x=(a-1)*5+1
            let y=x+pl*5-1
            pageview
            icli
        fi

    elif [[ "$input" = "z" ]]; then
        a=""
        if [[ ! -z $out ]]; then
            hits   #Neueinlesen des Suchergebnisses
            icli
        else
            echo "Es liegt keine Suchanfrage vor."
        fi

    elif [[ "$input" =~ ^d[hn]?[0-9]+$ || "$input" =~ ^[bhinw][0-9]+$ || "$input" =~ ^[0-9]+$ ]]; then
        filmnr=$(echo ${input//[!0-9]/}) # Variable $filmnr = Kommando ohne führenden Buchstaben
        if [[ $filmnr -gt $trefferzahl || $filmnr -eq 0 ]]; then
            echo "Kein Film mit dieser Nummer!"
        else
            # Bestätigung des ausgewählten Films
            echo "$out" | awk -F "\",\"" 'NR=='$filmnr'{print "Ausgewählt:", $4, "("$1":",$3")"}' | tr -d '\\'

            # ANSI-Escapesequenzen für URL-Farbe blau in Variablen,
            # wenn Option -o nicht gewählt
            if [[ -z $oopt ]]; then
                bluein="\\033[0;34m"
                blueout="\\033[0m"
            fi

            filmurl=$(echo "$out" | \
                awk -F "\",\"" 'NR=='$filmnr'{print $10}')
            # Abspielen des Videos in niedriger/hoher Qualität
            if [[ "$input" =~ ^[nh][0-9]+$ ]]; then
                if [[ "$input" == n* ]]; then
                    def=14   #Feld d. Ergebnisliste für niedr. Qualität in Variable def
                    qual="niedriger"
                else
                    def=16   #Feld d. Ergebnisliste für hohe Qualität in Variable def
                    qual="hoher"
                fi

                urlqual $def

                if [[ "$filmurl" == "" ]]; then
                    echo "Film nicht in $qual Auflösung verfügbar."
                else
                    echo -e "URL: $bluein$filmurl$blueout"
                    echo "Bitte etwas Geduld ..."
                    $player "$filmurl"
                    status=$?
                    if [ $status -ne 0 ]; then
                        echo "Diese URL konnte vom Player nicht abgespielt werden."
                    fi
                fi
            fi

            # Auflistung aller URLs (Kommando "i")
            if [[ "$input" == i* ]]; then
                if [[ ! -z $out ]]; then
                    echo "    [n] = Niedrige Qualität, [s] = Standardqualität, [h] = Hohe Qualität, [w] = Internetseite" |    #Legende der Abkürzungen \
                    ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )   #Worterhaltende Zeilenumbrüche (außer bei Option -w)
                    urlqual 14
                    if [[ "$filmurl" == "" ]]; then
                        echo "[n] nicht verfügbar"
                    else
                        echo -e "[n] $bluein$filmurl$blueout"
                    fi
                    stanurl=$(echo "$out" | awk -F "\",\"" 'NR=='$filmnr'{print $10}')
                    echo -e "[s] $bluein$stanurl$blueout"
                    urlqual 16
                    if [[ "$filmurl" == "" ]]; then
                        echo "[h] nicht verfügbar"
                    else
                        echo -e "[h] $bluein$filmurl$blueout"
                    fi
                    weburl=$(echo "$out" | awk -F "\",\"" 'NR=='$filmnr'{print $11}')
                    echo -e "[w] $bluein$weburl$blueout"
                else
                    echo "Es liegt keine Suchanfrage vor."
                fi
            fi

            # Download des Videos (Kommando "d...")
            qual="normaler"
            if [[ "$input" =~ ^d[hn]?[0-9]+$ ]]; then

                if [[ "$input" =~ ^d[hn][0-9]+$ ]]; then   #Film-URL für niedrige/hohe Qualität
                    if [[ "$input" == dn* ]]; then
                        def=14   #Feld d. Ergebnisliste für niedr. Qualität in Variable def
                        qual="niedriger"
                        urlqual $def
                    fi
                    if [[ "$input" == dh* ]]; then
                        def=16   #Feld d. Ergebnisliste für hohe Qualität in Variable def
                        qual="hoher"
                        urlqual $def
                    fi
                fi

                if [[ "$filmurl" == "" ]]; then
                    echo "Film nicht in $qual Auflösung verfügbar."
                else
                    ext="${filmurl##*.}"   #Dateiendung der Film-URL
                    echo -e "Download des Videos in $qual Qualität. \033[1mFalls gewünscht, bitte Speicherort und Dateiname anpassen.\033[0m"
                    if [[ "$ext" == "m3u8" ]]; then
                        xx="mp4"
                    else
                        xx=$ext
                    fi
                    read -ep "Speichern unter: " -i "$dldir/$(echo "$out" | awk -F "\",\"" -v ext=$xx 'NR=='$filmnr'{print $4"."ext}' | tr -d '\\' | tr ' ' '_' | tr '/' '-' )" downloadziel
                    if [[ "$ext" == "m3u8" ]]; then
                        # Prüfung, ob avconv (statt ffmpeg) verwendet wird
                        which avconv >/dev/null
                        status=$?
                        if [ $status -eq 0 ]; then
                            app="avconv"
                        else
                            app="ffmpeg"
                        fi
                        # Download mit FFmpeg/Libav
                        $app -i $filmurl -c copy -bsf:a aac_adtstoasc "$downloadziel"
                        echo -e "\033[1mTrefferliste kann mit Kommando z neu eingelesen werden.\033[0m"
                    else
                        curl -JL -o "$downloadziel" $filmurl
                    fi
                fi
            fi

            # Anzeige der Internetseite zur Sendung im Standardbrowser (Kommando "w")
            if [[ "$input" == w* ]]; then
                weburl=$(echo "$out" | awk -F "\",\"" 'NR=='$filmnr'{print $11}')
                echo -e "URL: $bluein$weburl$blueout"
                read -p "Soll die Internetseite zu dieser Sendung im Browser geöffnet werden? (J/n)" antwort
                if [[ "$antwort" = J || "$antwort" = j || "$antwort" = "" ]]; then
                    echo "Etwas Geduld bitte ..."
                    xdg-open $(echo "$out" | awk -F "\",\"" 'NR=='$filmnr'{print $11}') &
                    sleep 8
                fi
            fi

            # Speichern als Bookmark
            if [[ "$input" == b* ]]; then
                echo "$out" | \
                awk -F "\",\"" 'NR=='$filmnr'{print $4,"* "$10}' | tr -d '\\' >> $dir/bookmarks
                printf "\033[1mFilm ($filmnr) wurde als Bookmark gespeichert.\033[0m\nWechsel zur Bookmarkübersicht mit Kommando \033[1mB\033[0m.\n"
            fi

            # Abspielen des Videos in Standardauflösung
            if [[ "$input" =~ ^[0-9]+$ ]]; then
                echo "Bitte etwas Geduld ..."
                $player "$filmurl"
                status=$?
                if [ $status -ne 0 ]; then
                    echo "Diese URL konnte vom Player nicht abgespielt werden."
                fi
            fi
        fi
    else
        # Ausführen der Suche von der internen Kommandozeile
        if [ ! -z $oopt ]; then
            o="-o"
        fi
        if [ ! -z $wopt ]; then
            w="-w"
        fi
        if [[ $(echo -n $input | wc -m) -lt 3 && ! $input =~ ^[-] ]]; then
            echo "Suchanfragen mit weniger als drei Zeichen werden nicht unterstützt!"
        else
            H="-H"
            exec "$0" $H $o $w $input
        fi
    fi

done
}

# Defintion der FUNKTION bmcomm: Übersicht der Bookmark-Kommandos anzeigen
function bmcomm {
    printf '%.0s-' $(seq $(tput cols)); printf '\n'   #gestrichelte Trennlinie
    printf "\033[1mZum Abspielen Nummer des gewünschten Eintrags eingeben.\033[0m\n\033[1mq\033[0m beendet MediaTerm. \033[1mk\033[0m listet zusätzliche Kommando-Optionen auf.\n"
}

# Definition der FUNKTION bmcli: Kommandozeile Bookmarks
function bmcli {
    sed -i '/^\s*$/d' $dir/bookmarks   #entfernt eventuelle Leerzeilen aus der BM-Datei
    cat -b $dir/bookmarks | awk 'ORS="\n"{$1=$1;print}' | sed 'G'   #Aufbereitete Ausgabe der Bookmarks (mit Zeilennummerierung und Leerzeilen zw. Einträgen)
    bmcomm

    while [ 1 ]; do

    read -ep ">> " input
    history -s -- "$input"
    if [[ ! "$input" =~ ^[c,k,q,z,S]$ && ! "$input" =~ ^[0-9]+$ && ! "$input" = exit && ! "$input" = quit && ! "$input" =~ ^[al][0-9]+$ ]]; then
    echo "$input ist keine korrekte Eingabe."

    elif [[ "$input" == "k" ]]; then
        printf " \033[1ma\033[0m voranstellen (z.B. a5), um Bookmark als Suchergebnis anzuzeigen\n (= detaillierte Anzeige und zusätzliche Abspieloptionen, Trefferliste einer evtl. vorher durchgeführten Suche danach nicht mehr verfügbar!),\n \033[1mc\033[0m überprüft Gültigkeit aller Bookmarklinks,\n \033[1ml\033[0m voranstellen (z.B. l3), um Bookmark zu löschen,\n \033[1mz\033[0m liest Bookmarks neu ein,\n \033[1mS\033[0m wechselt in den Modus \"Suche/Treffer\".\n" | ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )

    elif [[ "$input" = "q" ||  "$input" = "exit" || "$input" = "quit" ]]; then
        exit   #Beenden des Programs bei Kommando "q"

    # Linkchecker mit curl (Kommando "c")
    elif [ "$input" = "c" ]; then
        filmmax=$(cat $dir/bookmarks | sed '/^\s*#/d;/^\s*$/d' | wc -l)   #Anzahl der Bookmarks (Zeilen ohne Leerzeilen)
        tabs 4
        for i in $(seq 1 $filmmax); do
            echo -e -n "$i\t"; curl -Is --max-time 6 $(cat -b $dir/bookmarks | awk '{$1=$1;print}' | grep "^${i}[ ]" | cut -d "*" -f2) | head -n 1
        done
        echo
        printf "\033[1mz\033[0m lädt Bookmarks neu.\n"
        bmcomm

    # Löschen eines Bookmarks, ${input//[!0-9]/} ist Nummer des zu löschenden Bookmarks
    elif [[ "$input" = l* ]]; then
        read -p "Soll Bookmark ${input//[!0-9]/} gelöscht werden (J/n)" antwort
        if [[ $antwort = J || $antwort = j || -z $antwort ]]; then
            sed -i '/^\s*$/d' $dir/bookmarks   #entfernt eventuelle Leerzeilen aus der BM-Datei
            sed -i "${input//[!0-9]/}d" $dir/bookmarks
            echo
            cat -b $dir/bookmarks | awk '{$1=$1;print}' | sed 'G'
            echo -e "\033[1mBookmark wurde gelöscht.\033[0m"
            bmcomm
        else
            echo "Es wurde kein Bookmark gelöscht."
        fi

    # Wechsel in den Modus "Suchen/Treffer" (Kommando "S")
    elif [ "$input" = "S" ]; then
        if [[ "$out" ]]; then
            hits
            icli
        else
            icli
        fi

    # Anzeigen von Bookmarks und Kommandoübersicht (Kommando "z")
    elif [ "$input" = "z" ]; then
        bmcli

    # Detaillierte Anzeige und Abspieloptionen, ${input//[!0-9]/} ist Nummer des Bookmarks
    elif [[ "$input" = a* ]]; then
        input=$(echo ${input//[!0-9]/})
        bmurl=$(cat -b $dir/bookmarks | awk '{$1=$1;print}' | grep "^${input}[ ]" | cut -d "*" -f2)
        out=$(grep $bmurl $dir/filmliste)
        suchanfrage=" Bookmark $input"
        echo   #Leerzeile
        hits
        icli

    # Abspielen der Bookmarks
    else
        echo "Bitte etwas Geduld ..."
        $player $(cat -b $dir/bookmarks | awk '{$1=$1;print}' | grep "^${input}[ ]" | cut -d "*" -f2)
        status=$?
        if [ $status -ne 0 ]; then
            echo "Diese URL konnte vom Player nicht abgespielt werden."
        fi
    fi
done
exit
}

# Definition der FUNKTION urlqual: setzt URLs niedriger und hoher Qualität zusammen.
# Parameter bestimmen sich nach Feldnummer von $out (14 niedrige, 16 hohe Qualität).
urlqual () {
filmurl=$(echo "$out" | \
    nl -s "\", \""  |    # Zeilennummerierung \
    awk -v url="$(echo "$out" | awk -F "\",\"" -v fn=$filmnr 'NR==fn{print $10}')" -v urlstammlaenge="$(echo "$out" | awk -F "\",\"" -v var="$1" -v fn=$filmnr 'NR==fn{print $var}' | cut -d"|" -f1)" -v urlsuffix="$(echo "$out" | awk -F "\",\"" -v var="$1" -v fn=$filmnr 'NR==fn{print $var}' | cut -d"|" -f2)" -F "\",\"" -v fn=$filmnr 'NR==fn{print substr(url,1,urlstammlaenge)urlsuffix}')
}

# Definition der FUNKTION pageview: Teilansicht mit fünf Treffern für Blätterfunktion
pageview () {
        echo
        echo "$out" | \
            awk -F "\",\"" '{ORS=" "}; {print "("NR")", "\033[0;32m"$4"\033[0m"" ("$1": "$3")"}; {if($14!=""){printf "[n"} else{printf "[-"}}; {if($16!=""){print "/h]"} else{print "/-]"}}; {print "\n"  "\33[1m""Datum:""\033[0m",$5  ",",  $6,"Uhr","*",  "\33[1m""Dauer:""\033[0m",  $7,"\n" $9,  "\n" "\033[0;34m"$10"\033[0m"} {printf "\n\n"}' | \
            awk -v x=$x -v y=$y 'NR==x,NR==y' | #nur 5/10 Treffer ab Nr. in Variable x \
            ( if [ ! -z $oopt ]; then sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"; else tee; fi ) |   #Entfernt Farbformatierungen bei Option -o \
            tr -d '\\' |   #Entfernt Escape-Backslashes aus Ausgabe \
            ( if [[ -z $wopt ]]; then fmt -s -w $(tput cols); else tee; fi )   #Worterhaltende Zeilenumbrüche (außer bei Option -w)

echo "[Suchanfrage:$suchanfrage] (Gefundene Filme: $trefferzahl, Blättern mit +/-)" #Anzeige der Suchanfrage unter der Trefferliste
}

# <<<<< ENDE FUNKTIONEN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#### Aufrufen, Abspielen und Löschen der Bookmarks (Option -b)
if [ ! -z $bopt ]; then
    if [ ! -f $dir/bookmarks ]; then
        echo "Die Datei $dir/bookmarks existiert nicht."
        exit
    fi
    bmcli   #Funktion bmcli
fi

#### Herunterladen der Filmliste (falls nicht vorhanden oder bei Option -u)
if [[ ! -f $dir/filmliste  || ! -z $uopt ]]; then
    read -p "Soll die aktuelle Filmliste heruntergeladen und im Verzeichnis $dir (wird ggf. vom Programm angelegt) gespeichert werden? (J/n)" antwort
    echo

    # Fall: Download-Frage bejaht
    if [[ $antwort = J || $antwort = j || -z $antwort ]]; then
        mkdir -p $dir
        # Download der gepackten Filmliste mit curl, wobei per Zufallsgenerator
        # einer der Filmlisten-Verteiler 3 bis 6 gewählt wird
        curl -v -o $dir/Filmliste-akt.xz "http://verteiler"$(( ( RANDOM % 4 )  + 3 ))".mediathekview.de/Filmliste-akt.xz"   #Herunterladen der komprimierten Filmliste
        echo "Die heruntergeladene Filmliste wird jetzt entpackt und aufbereitet ..."
        cd $dir
        unxz -f Filmliste-akt.xz   #Entpacken der Filmliste
        awk -v RS="\"X\"" 1 Filmliste-akt > Filmliste   #Ersetzen des Trenners "X" durch Zeilenumbruch
        cat Filmliste | awk -F "\"" '!/\[\"\"/ { sender = $2; } { print sender"\",\""$0; }' > filmliste1   #allen Zeilen Sender voranstellen
        cat filmliste1 | awk -F "\",\"" -v OFS="\",\"" '!($3==""){ thema = $3; } {sub($3,thema,$3); print}' > filmliste   #In alle Zeilen Thema einfügen
        rm Filmliste-akt Filmliste filmliste1   #Löschen nicht mehr benötigter Dateien

      # Fall: Download-Frage verneint
    else
        if [ ! -f $dir/filmliste ]; then
            printf "\033[1mOhne Filmliste funktioniert MediaTerm nicht.\033[0m \n"
            exit
        fi
    fi

    # Bei Option -u wird Programm nach Download beendet
    if [ ! -z $uopt ]; then
        exit
    fi
fi

#### Bei fehlendem Suchstring wird die interne Kommando(Such-)zeile ohne Trefferliste geöffnet (Ausnahme: Option -l, Livestreams).
if [[ -z $1 && -z $lopt ]]; then
    icli
fi

#### Suche (rohes Suchergebnis)

echo   #Leerzeile aus kosmetischen Gruenden

# Abbruch bei Suchanfragen mit weniger als 3 Zeichen (Ausnahme: Option -l)
if [ -z $lopt ]; then
for i in "${@}"; do
    string="$string""$i"
done
    if [ $(echo -n "$string" | wc -m) -lt 3 ]; then
        echo "Suchanfragen mit weniger als drei Zeichen werden nicht unterstützt!"
        echo -n "$string" | wc -m
        exit
    fi
fi

# Falls Option -l, Änderung des searchstrings zu "Livestream"
if [ ! -z $lopt ]; then
    out=$(grep $C -w "\"Livestream\"" $dir/filmliste)
else
    # Wenn Option -g NICHT gewählt, keine Unterscheidung zwischen Gross- und Kleinschreibung
    if [ -z $gopt ]; then
        c="-i"   #grep-Option -i (ignore case) in Variable c
    fi

    # Suchergebnis für ersten Suchstring
    if [[ $1 == \+* ]]; then
        out=$(tail -n +2 $dir/filmliste | grep $c -w "${1:1}")   #Exakte Wortsuche
    else
        out=$(tail -n +2 $dir/filmliste | grep $c "$1")
    fi
fi

# Filtern mit weiteren Suchstrings
for i in "${@:2}"; do
    if [[ $i == \+* ]]; then
        out=$(echo "$out" | grep $c -w "${i:1}")   #Exakte Wortsuche
    elif [[ $i == \~\+* ]]; then
        out=$(echo "$out" | grep $c -vw "${i:2}")  #Ausschluss eines exakten Wortes
    elif [[ $i == \~* ]]; then
        out=$(echo "$out" | grep $c -v "${i:1}")   #Ausschluss eines Strings
    else
        out=$(echo "$out" | grep $c "$i")   #Normale Stringsuche
    fi
done

# Filtern nach Zeitraum (Optionen -d, -e)
if [[ (! "$datum1" == "01.01.0000" || ! "$datum2" == "31.12.9999") ]]; then
    out=$(echo "$out" | awk -F"\",\"" 'OFS="\",\""{ n=split($5,b,".");$5=b[3]"."b[2]"."b[1];print }' |   #Datumsfelder ($5) werden zwecks Vergleich invertiert \
        awk -F "\",\"" -v t1="$datum1" -v t2="$datum2" '{if (($5 <= t2)&&($5 >= t1)) {print} }' |   #Vergleich der Datumsfelder mit Optionsargumenten; Filtern mit if-Anweisung \
        awk -F"\",\"" 'OFS="\",\""{ n=split($5,b,".");$5=b[3]"."b[2]"."b[1];print}')   #Zurückversetzen der Datumsfelder ($5) in ihr ursprüngliches Format
fi

#### Sortieren nach Sendedatum (Optionen -s, -t)
# Sortierung aufsteigend
if [ ! -z $topt ]; then
    out=$(echo "$out" | awk -F "\",\"" '{print $5"-"$0}' | sort -t"." -n -k3 -k2 -k1 | cut -d "-" -f 2-)
fi
# Sortierung absteigend
if [ ! -z $sopt ]; then
    out=$(echo "$out" | awk -F "\",\"" '{print $5"-"$0}' | sort -t"." -r -n -k3 -k2 -k1 | cut -d "-" -f 2-)
fi

#### Formatierung und Ausgabe des Suchergebnisses
hits   #Funktion hits

#### Filme abspielen, herunterladen, als Bookmark speichern (interne Kommandozeile)
icli   #Funktion icli


