#!/bin/bash
cp -r ~/.config/hypr .
cp -r ~/.config/waybar .
cp -r ~/.config/helix .

git add .
git commit -m "up"
git push origin main
