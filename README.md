# Drone-Computer-Vision-Distributed-Control-Swarm

# tello_swarm

Course files for **Kursus Upskilling: Autonomous Drone Vision Programming and Distributed Control**.

A DJI Tello EDU is flown from a Raspberry Pi 5. One overhead camera finds the ArUco marker on each drone. The camera Pi sends every position to each group's Raspberry Pi over Ethernet.

## Install

On a Raspberry Pi with an internet connection:

```bash
curl -fsSL https://raw.githubusercontent.com/zoolfahmy/tello_swarm/main/install.sh | bash
```

This puts the files in `~/tello_swarm` and creates the Python environment `swarm_env` (OpenCV, NumPy, djitellopy). Run the same line again to update. Files you already have are kept.

## Run

Every session:

```bash
cd ~/tello_swarm
source swarm_env/bin/activate
```

Camera Pi (after the arena is calibrated):

```bash
python shared_vision/camera_host.py
```

Each group's Raspberry Pi:

```bash
python shared_vision/vision_client.py                  # check the link to the camera
python shared_vision/fly_step10.py --sim --marker 1    # dry run, no drone
python shared_vision/fly_step10.py --marker 1          # real flight, facilitator only
```

Replace `1` with the marker ID on the drone.

## Keys

| Key | Action |
| --- | --- |
| A | arm or disarm |
| T | take off (only while armed) |
| L or SPACE | land now |
| E | emergency: stop the motors |
| Q | quit |

## Files

One Python file for every task of the Participant Module. The full list is in [TASK_FILES.txt](TASK_FILES.txt).

| Folder | Day | Content |
| --- | --- | --- |
| `practical01`, `practical02` | 1 | camera test, ArUco markers, arena calibration |
| `practical03`, `practical04` | 2, 3 | Tello flights, altitude hold, XY loop, log analysis |
| `practical05` | 4 | positions of several markers |
| `shared_vision` | 1 to 4 | camera host, link check, flight launcher |

## Notes

- Put every Raspberry Pi on one Ethernet switch. The Wi-Fi of each group's Pi stays on its own Tello.
- Use one marker ID for each drone (ID1 to ID4).
- Calibrate the arena again whenever the camera is moved, then restart `camera_host.py`.
- The scripts in `shared_vision` have been tested in simulation only. A complete autonomous flight cycle is not yet flight-validated, and multi-drone flight is not flown in this course.

## Author

Ts. Mohd Zul Fahmi Bin Mohd Zawawi, Politeknik Sultan Abdul Halim Mu'adzam Shah (POLIMAS)


