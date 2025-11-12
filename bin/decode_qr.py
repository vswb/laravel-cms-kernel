import cv2
import numpy as np
from pyzbar.pyzbar import decode

# Đọc ảnh
image = cv2.imread("qr.png")
data = decode(image)

for obj in data:
    print("Nội dung QR:", obj.data.decode("utf-8"))
