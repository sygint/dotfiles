#!/usr/bin/env bash
# Screenshot tool using grim, slurp, and swappy
grim -g "$(slurp)" - | swappy -f -
