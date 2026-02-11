import os
os.environ["OPENCV_VIDEOIO_MSMF_ENABLE_HW_TRANSFORMS"] = "0"
import cv2 as cv
import numpy as np

# Create a VideoCapture object. The argument '0' specifies the default camera.
# Use '1' or higher for additional cameras.
cap = cv.VideoCapture(1)

# Check if the camera opened successfully
if not cap.isOpened():
    print("Cannot open camera")
    exit()

while True:
    # Capture frame-by-frame. 'ret' is True if the frame was read correctly.
    ret, frame = cap.read()

    if not ret:
        print("Can't receive frame (stream end?). Exiting ...")
        break

    # Display the resulting frame
    cv.imshow('Live Camera Feed', frame)

    # Press 'q' on the keyboard to exit the loop and close the window
    if cv.waitKey(1) == ord('q'):
        break

# When everything is done, release the capture and destroy all windows
cap.release()
cv.destroyAllWindows()