import asyncio
import websockets
import json
import os
os.environ["OPENCV_VIDEOIO_MSMF_ENABLE_HW_TRANSFORMS"] = "0"
import cv2
import base64

# Global variable for the camera
camera = None
streaming = False
def initialize_camera(index):
    """Initialize camera with proper release of any existing camera"""
    global camera
    
    # Release any existing camera
    if camera is not None:
        camera.release()
        camera = None
    
    
    # Wait a bit for camera to fully release
    import time
    time.sleep(0.5)
    
    # Open new camera
    print(f"Opening camera {index} with CAP_DSHOW...", flush=True)
    cam = cv2.VideoCapture(index, cv2.CAP_DSHOW)
    
    if cam.isOpened():
        # Test read
        ret, frame = cam.read()
        if ret:
            width = int(cam.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cam.get(cv2.CAP_PROP_FRAME_HEIGHT))
            print(f"Camera {index} opened: {width}x{height}", flush=True)
            return cam
        else:
            print(f"Camera {index} opened but can't read frames", flush=True)
            cam.release()
            return None
    else:
        print(f"Failed to open camera {index}", flush=True)
        return None
    
async def capture_and_send(websocket):
    global camera, streaming
    
    # Initialize camera if not already done
    if camera is None:
        camera = initialize_camera(1)  # 0 is usually the default camera
        if not camera.isOpened():
            print("Error: No cameras", flush=True)
            
    
    streaming = True
    print("Starting camera", flush=True)
    
    try:
        while streaming:
            cam_suc, frame = camera.read()
            if not cam_suc:
                print("Error: camera failed", flush=True)
                break

            frame = cv2.flip(frame, 1)
            frame = cv2.resize(frame, (640, 480))
            
            # Encode frame as JPEG
            _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
            
            # Convert to base64
            frame_base64 = base64.b64encode(buffer).decode('utf-8')
            
            # Send frame data
            message = {
                "data": frame_base64
            }
            
            await websocket.send(json.dumps(message))
            
            # Control frame rate (30 FPS)
            await asyncio.sleep(1/30)
            
    except websockets.exceptions.ConnectionClosed:
        print("Connection closed during streaming", flush=True)
        streaming = False

async def handler(websocket):
    global streaming
    print("Client connected", flush=True)
    
    try:
        async for message in websocket:
            print(f"Received command: {message}", flush=True)
            
            data = json.loads(message)
            command = data.get("command", "")
            
            if command == "start_stream":
                await capture_and_send(websocket)
                
    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected", flush=True)
        streaming = False

async def main():
    global camera
    camera = initialize_camera(1)
    print("Starting websocket server on ws://localhost:8779", flush=True)
    
    async with websockets.serve(handler, "localhost", 8779):
        await asyncio.Future()  # run forever

def cleanup():
    global camera
    if camera is not None:
        camera.release()
        print("Camera released", flush=True)

if __name__ == "__main__":
    try:
        
        asyncio.run(main())
    finally:
        cleanup()