# timelapse

Timelapse camera scripts - [see details here](https://www.printables.com/model/250692-raspberry-pi-timelapse-camera-case).

- ![capture.sh](./capture.sh) - Uses `libcamera` to take a picture, using date/time format file name
- ![generate-timelapse.sh](./generate-timelapse.sh) – Uses `ffmpeg` to combine images into a timelapse video, including a blend showing a comparison between two images