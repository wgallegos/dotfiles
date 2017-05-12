#!/bin/bash
set -ue

# Installs necessary terminfos for tmux and iTerm2 on macOS

# Based on < https://apple.stackexchange.com/questions/249307/tic-doesnt-read-from-stdin-and-segfaults-when-adding-terminfo-to-support-italic#comment309243_249307 >
mkdir -p ~/.terminfo
export TERMINFO=~/.terminfo
curl http://invisible-island.net/datafiles/current/terminfo.src.gz | gunzip > "$TERMINFO/terminfo.src"
tic -x -e tmux "$TERMINFO/terminfo.src"
tic -x -e tmux-256color "$TERMINFO/terminfo.src"

tic -x ./terminfo/iterm2.terminfo
