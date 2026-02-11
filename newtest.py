import os
os.environ["OPENCV_VIDEOIO_MSMF_ENABLE_HW_TRANSFORMS"] = "0"
import cv2
import json
import base64
# Create a VideoCapture object to access the default camera (index 0)
# Change index to 1 or higher for external cameras
available_cameras = []
for i in range(10):  # Check first 10 indices
    #print(i)
    cap = cv2.VideoCapture(i)
    
    if cap.isOpened():
       # print(i)
        available_cameras.append(i)

print(available_cameras)