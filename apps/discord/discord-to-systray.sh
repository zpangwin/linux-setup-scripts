#!/usr/bin/env python3
import subprocess
import sys
import time

# This script was adapted from this answer https://askubuntu.com/a/663288 posted by Jacob Vlijm
# The only changes are as follows:
#    1. explicitly hard-coded Discord paths / window name
#    2. adjusted the check frequency from 0.1 seconds to 0.05 seconds
#    3. increased max time to check for window from 3 seconds to 30 seconds
#    4. Changing windowminimize to windowclose (so that discord gets minimize to the systray instead of taskbar)
# Thanks and enjoy - zpangwin

subprocess.Popen(["/usr/bin/discord"])
time.sleep(1)
windowName = "Activity - Discord"

def read_wlist(w_name):
    try:
        l = subprocess.check_output(["wmctrl", "-l"]).decode("utf-8").splitlines()
        return [w.split()[0] for w in l if w_name in w][0]
    except (IndexError, subprocess.CalledProcessError):
        return None

# I have increased this time to give discord more time to update but
# it may need to be adjusted more/less depending on if you want updates
# to be exempted from the miminize scenario, internet speed, CPU, etc
secondsWaited = 0
checkFreqInSec = 0.5
maxTimeInSec = 30

while secondsWaited < maxTimeInSec:
    windowId = read_wlist(windowName)
    time.sleep(checkFreqInSec)
    if windowId != None:
        subprocess.Popen(["xdotool", "windowclose", windowId])
        break
    secondsWaited += checkFreqInSec

print("script complete")
