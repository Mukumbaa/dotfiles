#!/bin/bash
cp -r ~/.config/hypr .
cp -r ~/.config/waybar .
cp -r ~/.config/helix .
cp -r ~/.config/btop .

git add .
git commit -m "up"
git push origin main
