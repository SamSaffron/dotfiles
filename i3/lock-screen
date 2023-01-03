#!/bin/bash

B='#00000000'  # blank
C='#ffffff22'  # clear ish
D='#00000000'  # default
T='#f0ffffff'  # text
W='#ee0000bb'  # wrong
V='#bb00bbbb'  # verifying

BG="#000000ff"

# -e to ignore empty password

i3lock \
--greeter-text="" \
-c $BG \
--insidever-color=$C   \
--ringver-color=$V     \
\
--insidewrong-color=$C \
--ringwrong-color=$W   \
\
--inside-color=$B      \
--ring-color=$D        \
--line-color=$B        \
--separator-color=$D   \
\
--verif-color=$T        \
--wrong-color=$T        \
--time-color=$T        \
--date-color=$T        \
--layout-color=$T      \
--keyhl-color=$W       \
--bshl-color=$W        \
\
--screen 1            \
--clock               \
--indicator           \
--time-str="%H:%M:%S"  \
--date-str="%A, %m %Y" \
--keylayout 1         \
