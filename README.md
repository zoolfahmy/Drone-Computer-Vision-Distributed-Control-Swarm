# Drone Computer Vision and Distributed Control Swarm

Course files for **Kursus Upskilling: Autonomous Drone Vision Programming and Distributed Control**.

A DJI Tello EDU is flown from a Raspberry Pi 5. One overhead camera finds the ArUco marker on each drone. The camera Pi sends every position to each group's Raspberry Pi over Ethernet.

## Install

On a Raspberry Pi with an internet connection:

```bash
curl -fsSL https://raw.githubusercontent.com/zoolfahmy/Drone-Computer-Vision-Distributed-Control-Swarm/main/install.sh | bash
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
python shared_vision/step11_hold.py --sim --wp 10,0    # Step 11 hold + waypoint, no drone
```

Step 11 and the swarm (facilitator flights, see `shared_vision/README.txt`):

```bash
python shared_vision/step11_hold.py --wp 10,0 --hold 8 --confirm WP-RC18   # one drone, hold + 10 cm waypoint
python shared_vision/swarm_coordinator.py --markers 1,2 --confirm SWARM-GO-2 # camera Pi
python shared_vision/step11_hold.py --swarm --marker 1 --confirm HOLD-RC18  # each flight Pi, own marker
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
| `practical01`, `practical02` | 1 | camera test, basic OpenCV (colour, mask, contour, edges, object detection), ArUco markers, arena calibration |
| `practical03`, `practical04` | 2, 3 | Tello flights, altitude hold, XY loop, log analysis |
| `practical05` | 4 | positions of several markers |
| `shared_vision` | 1 to 4 | camera host, link check, flight launcher, Step 11 hold, swarm coordinator |

## Notes

- Put every Raspberry Pi on one Ethernet switch. The Wi-Fi of each group's Pi stays on its own Tello.
- Use one marker ID for each drone (ID1 to ID4).
- Calibrate the arena again whenever the camera is moved, then restart `camera_host.py`.
- Flight status, 7 October 2026 (course arena):
  - `step11_hold.py` flew a complete autonomous cycle (take off, hold, 10 cm waypoint accepted, guided descent, land) in 2 of 7 attempts. Hold error averaged 3 cm. The other attempts were stopped safely by the drift and take-off limits.
  - Two drones on two Raspberry Pis took off together on the coordinator's GO and landed together on LAND_ALL. A complete two-drone mission has not been flown yet.
  - `fly_step10.py`, `observe_flight.py` and `vertical_projection.py` are still tested in simulation only.
- Switch a Tello on only when its group is ready to fly. Above about 62 °C a take-off can go unanswered.
- A glossy floor makes the Tello drift. A patterned mat under each drone helps.

## Author

Ts. Mohd Zul Fahmi Bin Mohd Zawawi, Politeknik Sultan Abdul Halim Mu'adzam Shah (POLIMAS)
