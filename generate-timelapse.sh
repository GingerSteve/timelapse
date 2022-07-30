#!/bin/bash

# ----- VARIABLES -----

# Generates a timelapse at 2k resolution (ish)
FRAMERATE=24 # Number of frames per second
WIDTH=2048
HEIGHT=1536

ENABLE_BLEND=true                               # Adds transition at the end of the timelapse, to compare two images
BLEND_IMG_START=./timelapse/20220729_090001.jpg # "Before" image
BLEND_IMG_END=./timelapse/20220729_171901.jpg   # "After" image

BLEND_LENGTH=2                                     # Length in seconds of the blend transition
BLEND_PAUSE=1                                      # How long to sit on images between blends
BLEND_TOTAL_LENGTH=$((BLEND_LENGTH + BLEND_PAUSE)) # Length in seconds of the blend clips – will stay on the last frame until time's up

INPUT_GLOB=./timelapse/*.jpg               # Input image name pattern
TIMELAPSE_NAME=./timelapse/timelapse.mp4   # Output timelapse name
FINAL_NAME=./timelapse/timelapse_final.mp4 # Final output name, with blends

# Temporary blend output files – these are cleaned up at the end
BLEND0=blend0.mp4
BLEND1=blend1.mp4
BLEND2=blend2.mp4

# ----- SCRIPT -----

# If any command fails, exit immediately
set -e

printf "\n\nGENERATING TIMELAPSE\n\n"
# `-framerate` must be before the image input, it defines the input rate of the image demuxer
ffmpeg -framerate $FRAMERATE -pattern_type glob -i "$INPUT_GLOB" -vf scale=$WIDTH:$HEIGHT $TIMELAPSE_NAME

if [ "$ENABLE_BLEND" = true ]; then
    printf "\n\nBLENDS\n\n"
    # Define the blend filter
    FILTER="[1:v][0:v]blend=all_expr='A*(if(gte(T,$BLEND_LENGTH),1,T/$BLEND_LENGTH))+B*(1-(if(gte(T,$BLEND_LENGTH),1,T/$BLEND_LENGTH)))'[v];[v]scale=$WIDTH:$HEIGHT"

    # Stay on the BLEND_IMG_END for BLEND_PAUSE
    ffmpeg -loop 1 -i $BLEND_IMG_END -r $FRAMERATE -t $BLEND_PAUSE -vf scale=$WIDTH:$HEIGHT $BLEND0

    # Blend from the BLEND_IMG_END to BLEND_IMG_START, then back
    ffmpeg -loop 1 -i $BLEND_IMG_END -loop 1 -i $BLEND_IMG_START -r $FRAMERATE -filter_complex $FILTER -t $BLEND_TOTAL_LENGTH $BLEND1
    ffmpeg -loop 1 -i $BLEND_IMG_START -loop 1 -i $BLEND_IMG_END -r $FRAMERATE -filter_complex $FILTER -t $BLEND_TOTAL_LENGTH $BLEND2

    printf "\n\nCONCATENATING\n\n"
    # Concatenate the timelapse and blends
    ffmpeg -i $TIMELAPSE_NAME -i $BLEND0 -i $BLEND1 -i $BLEND2 -filter_complex "concat=n=4:v=1[v]" -map [v] $FINAL_NAME
    # Remove blend files
    rm $BLEND0 $BLEND1 $BLEND2
fi
