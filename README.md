# MotionCapture

An iOS application for capturing motion data from the phone and peripherals like the TI SensorTag.

## Overview

MotionCapture is a utility for capturing raw sensor motion data.  I created it to support algorithm development of activity trackers.  It does not provide any high-level tracking capability itself, just labeling and recording of the raw sensor data.

## Features

 * Records the motion of the local device (raw sensors and/or fused `CMDeviceMotion` data)
 * Records the motion of multiple Bluetooth peripherals (currently only supports TI SensorTags)
 * Automatically reconnects to Bluetooth peripherals when connection drops
 * User can name the devices and label them with body locations (e.g. "right wrist")
 * User can choose which sensors to record and the sample rates independently for each device
 
## Status

Currently functional, but preliminary.  The biggest current drawback is that there is no export or sharing.  You need to download the data using the Xcode organizer.  There are also placeholders in the user interface for indicating the amount of motion for each device (to make it easier to name and label them), but those are not currently hooked up.
