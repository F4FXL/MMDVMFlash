#!/bin/bash
set -euo pipefail

UART="/dev/ttyAMA0"
BIN="bin/mmdvm_f7.bin"
BAUD=115200   # si besoin: 57600

BOOT=20
NRST=21

cleanup() {
  # Make sure we always exit bootloader at the end
  pinctrl $BOOT op dl || true
  sleep 0.1
  pinctrl $NRST op dl || true
  sleep 0.2
  pinctrl $NRST op dh || true
}
trap cleanup EXIT

# Init cleanly
pinctrl $NRST op dh
pinctrl $BOOT op dl
sleep 0.2

# Enter bootloader
pinctrl $BOOT op dh
sleep 0.2
pinctrl $NRST op dl
sleep 0.2
pinctrl $NRST op dh
sleep 2

echo "Waiting for bootloader response on $UART @ $BAUD (accept 79 or 1f)..."

ok=0
for i in $(seq 1 80); do
  # Send 0x7f and wait for any answer
  res="$(python3 - <<PY
import serial, time
try:
    s=serial.Serial("$UART",$BAUD,bytesize=8,parity=serial.PARITY_EVEN,stopbits=1,timeout=0.2)
    time.sleep(0.02)
    s.reset_input_buffer()
    s.write(b'\\x7f')
    r=s.read(1)
    s.close()
    print(r.hex() if r else "")
except Exception:
    print("")
PY
)"
  # 79=ACK, 1f=NACK we are happy with any response from the bootloader, ff=idle/bruit
  if [ "$res" = "79" ] || [ "$res" = "1f" ]; then
    ok=1
    echo "Bootloader answered (0x$res) on try $i. Flashing..."
    break
  fi
  sleep 0.05
done

if [ "$ok" -ne 1 ]; then
  echo "ERROR: no bootloader response (79/1f)."
  exit 1
fi

# Flash the firmware !
/usr/bin/stm32flash -b "$BAUD" -w "$BIN" -g 0x0 "$UART"
echo "Flash done."
