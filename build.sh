#!/bin/bash
# THE ASCENT — Snowmoon Chapter 6 (poidh bounty #34)
# Reproducible build: stills (AI) -> zoompan segments -> xfade assembly ->
# synthesized audio -> subtitles + end card -> final 1920x1080, crf 18.
# Stills-only pipeline: media.generate_video returned 403 (region-blocked),
# so all motion is ffmpeg pan/zoom (Ken Burns), documented in PROCESS.md.
set -euo pipefail

ROOT="$HOME/workspace/snowmoon-keeper"
STILLS="$ROOT/stills"
SEG="$ROOT/build/seg"
FINAL="$ROOT/final"
FPS=30
W=1920; H=1080
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

mkdir -p "$SEG" "$FINAL"

echo "[0/5] copying stills to clean names"
cp "$STILLS/shot1_path.png"           "$SEG/shot1.png"
cp "$STILLS/shot2_turn.png"           "$SEG/shot2.png"
cp "$STILLS/shot3_staircase_wide.png" "$SEG/shot3.png"
cp "$STILLS/shot4_climb.png"          "$SEG/shot4.png"
cp "$STILLS/shot5_top.png"            "$SEG/shot5.png"
cp "$STILLS/shot6_circle_dark.png"    "$SEG/shot6.png"
cp "$STILLS/shot7_circle_lit.png"     "$SEG/shot7lit.png"
cp "$STILLS/shot8_device.png"         "$SEG/shot8.png"
cp "$STILLS/endcard_bg.png"           "$SEG/endcard.png"

mkseg () { # $1=input $2=frames $3=zoompan-params $4=output
  ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -framerate $FPS -i "$1" \
    -vf "scale=$W:$H,zoompan=$3:d=$2:s=${W}x${H}:fps=$FPS" \
    -frames:v "$2" -c:v libx264 -preset medium -crf 12 -pix_fmt yuv420p "$4"
}

echo "[1/5] rendering zoompan segments (30fps)"
CX="x='iw/2-(iw/zoom/2)'"; CY="y='ih/2-(ih/zoom/2)'"
mkseg "$SEG/shot1.png" 300 "z='1+0.08*on/300':$CX:$CY"                    "$SEG/seg1.mp4"
mkseg "$SEG/shot2.png" 240 "z=1.12:x='(iw-iw/zoom)*(1-on/240)':$CY"       "$SEG/seg2.mp4"
mkseg "$SEG/shot3.png" 420 "z='1+0.10*on/420':$CX:$CY"                   "$SEG/seg3.mp4"
mkseg "$SEG/shot4.png" 300 "z=1.12:$CX:y='(ih-ih/zoom)*(1-on/300)'"       "$SEG/seg4.mp4"
mkseg "$SEG/shot5.png" 240 "z='1.12-0.12*on/240':$CX:$CY"                 "$SEG/seg5.mp4"
mkseg "$SEG/shot6.png" 300 "z='1+0.06*on/300':$CX:$CY"                   "$SEG/seg6.mp4"
mkseg "$SEG/shot6.png" 135 "z='1.06+0.02*on/135':$CX:$CY"                "$SEG/seg7d.mp4"
mkseg "$SEG/shot7lit.png" 360 "z='1.08+0.04*on/360':$CX:$CY"             "$SEG/seg7l.mp4"
mkseg "$SEG/shot8.png" 300 "z='1+0.04*on/300':$CX:$CY"                   "$SEG/seg8.mp4"
mkseg "$SEG/endcard.png" 180 "z=1.0:$CX:$CY"                             "$SEG/segE.mp4"

echo "[2/5] shot7: dark -> lit crossfade at the watch tap (t=3.0..4.5 of shot7)"
ffmpeg -y -hide_banner -loglevel error \
  -i "$SEG/seg7d.mp4" -i "$SEG/seg7l.mp4" \
  -filter_complex "[0:v][1:v]xfade=transition=fade:duration=1.5:offset=3,format=yuv420p[v]" \
  -map "[v]" -c:v libx264 -preset medium -crf 12 "$SEG/seg7.mp4"

echo "[3/5] assembling master with 1s crossfades (total 83s)"
ffmpeg -y -hide_banner -loglevel error \
  -i "$SEG/seg1.mp4" -i "$SEG/seg2.mp4" -i "$SEG/seg3.mp4" -i "$SEG/seg4.mp4" \
  -i "$SEG/seg5.mp4" -i "$SEG/seg6.mp4" -i "$SEG/seg7.mp4" -i "$SEG/seg8.mp4" \
  -i "$SEG/segE.mp4" \
  -filter_complex "\
[0:v][1:v]xfade=transition=fade:duration=1:offset=9[x1];\
[x1][2:v]xfade=transition=fade:duration=1:offset=16[x2];\
[x2][3:v]xfade=transition=fade:duration=1:offset=29[x3];\
[x3][4:v]xfade=transition=fade:duration=1:offset=38[x4];\
[x4][5:v]xfade=transition=fade:duration=1:offset=45[x5];\
[x5][6:v]xfade=transition=fade:duration=1:offset=54[x6];\
[x6][7:v]xfade=transition=fade:duration=1:offset=68[x7];\
[x7][8:v]xfade=transition=fade:duration=1:offset=77,format=yuv420p[vout]" \
  -map "[vout]" -c:v libx264 -preset medium -crf 12 "$SEG/master.mp4"

echo "[4/5] synthesizing audio (wind + drone score + chime, no stock music, no VO)"
echo "      (deterministic numpy synthesis — see make_audio.py)"
python3 "$ROOT/make_audio.py"
ffmpeg -y -hide_banner -loglevel error -i "$SEG/audio.wav" \
  -c:a aac -b:a 192k -ar 48000 "$SEG/audio.m4a"

echo "[5/5] final: device text + subtitles + end card -> 1920x1080 crf 18"
ffmpeg -y -hide_banner -loglevel error \
  -i "$SEG/master.mp4" -i "$SEG/audio.m4a" \
  -vf "\
drawtext=fontfile=$FONT:text='Request confirmed.':fontcolor=0x8CFFB0:fontsize=32:x=1280-text_w/2:y=652-text_h/2:alpha='if(between(t,73.5,77),if(lt(t,74.5),(t-73.5),if(gt(t,76),(77-t),1)),0)',\
subtitles=$ROOT/subs.srt:force_style='FontName=DejaVu Sans,FontSize=26,PrimaryColour=&H00FFFFFF,OutlineColour=&H80000000,BorderStyle=1,Outline=2,Shadow=1,Alignment=2,MarginV=60',\
drawtext=fontfile=$FONT:text='THE ASCENT':fontcolor=white:fontsize=76:x=(w-text_w)/2:y=h*0.34:alpha='if(between(t,77.5,83),min((t-77.5),1),0)',\
drawtext=fontfile=$FONT:text='Adapted from Snowmoon (GPL v3) by Vitalik Buterin':fontcolor=white:fontsize=34:x=(w-text_w)/2:y=h*0.53:alpha='if(between(t,77.8,83),min((t-77.8),1),0)',\
drawtext=fontfile=$FONT:text='Chapter 6 — Keeper Confirmation':fontcolor=white:fontsize=34:x=(w-text_w)/2:y=h*0.60:alpha='if(between(t,77.8,83),min((t-77.8),1),0)',\
drawtext=fontfile=$FONT:text='An AI-assisted film · open production pipeline':fontcolor=white:fontsize=30:x=(w-text_w)/2:y=h*0.68:alpha='if(between(t,77.8,83),min((t-77.8),1),0)'" \
  -map 0:v -map 1:a -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
  -c:a aac -b:a 192k -movflags +faststart -shortest "$FINAL/the-ascent.mp4"

echo "claim still + contact sheet"
ffmpeg -y -hide_banner -loglevel error -ss 58.6 -i "$FINAL/the-ascent.mp4" \
  -frames:v 1 "$FINAL/claim-still.png"
for t in 4.5 12.5 22.5 33 41 49.5 61 72 80; do
  ffmpeg -y -hide_banner -loglevel error -ss $t -i "$FINAL/the-ascent.mp4" \
    -frames:v 1 -vf "scale=640:360" "$SEG/qc_$t.png"
done
ffmpeg -y -hide_banner -loglevel error \
  -i "$SEG/qc_4.5.png" -i "$SEG/qc_12.5.png" -i "$SEG/qc_22.5.png" \
  -i "$SEG/qc_33.png" -i "$SEG/qc_41.png" -i "$SEG/qc_49.5.png" \
  -i "$SEG/qc_61.png" -i "$SEG/qc_72.png" -i "$SEG/qc_80.png" \
  -filter_complex "[0:v][1:v][2:v]hstack=inputs=3[r1];[3:v][4:v][5:v]hstack=inputs=3[r2];[6:v][7:v][8:v]hstack=inputs=3[r3];[r1][r2][r3]vstack=inputs=3" \
  "$FINAL/qc-contact-sheet.jpg"

echo "verify"
ffprobe -v error -show_entries format=duration,size \
  -show_entries stream=width,height,codec_name -of default=noprint_wrappers=1 \
  "$FINAL/the-ascent.mp4"
ls -la "$FINAL/"
echo DONE
