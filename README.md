# MMDVMFlash
Simple script to flash MMDVM boards on kernels only supporting libgpiod.

## Prerequisites
- pinctrl https://github.com/raspberrypi/utils/tree/master/pinctrl
- stm32flash `apt install stm32flash`
- python3 and python_serial

## Usage
Edit the script to fit your setup ie change UART,BIN BOOT and RESET pins.
