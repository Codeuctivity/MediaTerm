mediaterm.sh
============

# First use

Install dependencies
```bash
sudo apt install curl
```

Download
```bash
wget https://raw.githubusercontent.com/Codeuctivity/MediaTerm/master/mediaterm.sh
```

Make it executable
```bash
chmod +x mediaterm.sh
```
Run it interactive
```bash
./mediaterm.sh
```

# Description
Mit dem Bash-Skript MediaTerm lassen sich Filme aus den Mediatheken der öffentlich-rechtlichen Fernsehsender ressourcenschonend im Linux-Terminal suchen, abspielen, herunterladen und als Bookmarks speichern. Voraussetzung für das Abspielen der Filme ist der Medienplayer mpv, der aus den Paketquellen der gängigen Linux-Distributionen installiert werden kann. Außerdem müssen curl (ab MediaTerm Version 5.3; für ältere Versionen wget), xz-utils und entweder ffmpeg oder libav-tools installiert sein.

Bei der ersten Suchanfrage mit MediaTerm erfolgt (nach Bestätigung durch den Benutzer) automatisch ein Download der Filmliste von MediathekView (Filmliste-akt.xz), die im – ebenfalls automatisch vom Skript angelegten – Verzeichnis $HOME/MediaTerm entpackt und aufbereitet wird. Später lässt sich die Filmliste jederzeit durch Verwendung der Option "-u" aktualisieren.

Initial author: Martin O'Connor (mar.oco@arcor.de)
Initial source: http://martikel.bplaced.net/skripte1/mediaterm.html
