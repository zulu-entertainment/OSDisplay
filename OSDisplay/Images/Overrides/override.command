#!/bin/bash


targetDir=/Applications/OSDisplay.app/Contents/Resources
sourceDir=/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/Resources/BezelUI/HiDPI

printf 'Copy images from BezelUI...\n'
cp $sourceDir/Brightness.pdf $targetDir/brightness.pdf
cp $sourceDir/Eject.pdf $targetDir/eject.pdf

cd `dirname $0`
printf 'Copy all custom PNG images...\n'
cp *.png $targetDir
printf 'Copy all custom PDF images...\n'
cp *.pdf $targetDir




