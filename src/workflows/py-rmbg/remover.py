import os
import torch
import numpy as np
import numpy.typing as npt
import cv2
from pathlib import Path

CWD = os.path.dirname(__file__)
print(f"Current Directory: {CWD}\n")

CKPT_FILE = os.path.join(CWD, "20240829_183613_model.pth")

# Get the current script's directory
current_dir = Path(__file__).parent

# Define input and output folders relative to the current directory
input_folder = current_dir / "input"
output_folder = current_dir / "output"

print(f"Absolute input_folder path: {input_folder.resolve()}")
print(f"Absolute output_folder path: {output_folder.resolve()}")

# Ensure the input and output directories exist
input_folder.mkdir(parents=True, exist_ok=True)
output_folder.mkdir(parents=True, exist_ok=True)

if not os.path.exists(CKPT_FILE):
    raise FileNotFoundError(f"Model file not found: {CKPT_FILE}")

if torch.cuda.is_available():
    device = torch.device("cuda")
else:
    device = torch.device("cpu")

MODEL = torch.load(CKPT_FILE, map_location=device, weights_only=False) # type: ignore
MODEL.eval()

DSIZE = 512
MASK_THRESHOLD = 0.5
     
def inference(image: npt.NDArray[np.uint8]) -> npt.NDArray[np.uint8]:

    image_height, image_width = image.shape[:2]
    image = np.array(cv2.resize(image, (DSIZE, DSIZE))).astype(np.uint8)
    image_fl: npt.NDArray[np.float32] = cv2.cvtColor(image, cv2.COLOR_BGR2RGB).astype(np.float32)/255
    image_tensor = torch.tensor(image_fl, dtype=torch.float32).permute(2, 0, 1).unsqueeze(0)
    image_tensor = image_tensor.to(device)

    with torch.no_grad():
        pred = MODEL(image_tensor)[0]

    mask_fl = np.zeros((DSIZE, DSIZE), dtype=np.float32)
    max_score = 0

    for box, label, score, mask in zip(pred["boxes"], pred["labels"], pred["scores"], pred["masks"]):
        if label == 0:
            continue

        score_fl: float = float(score)
        if score_fl < 0.5:
            continue

        if score_fl < max_score:
            continue

        max_score = score_fl

        box_fl = box.cpu().detach().numpy().astype(np.int32)
        # print(f"box_fl: {box_fl}")

        data = mask.cpu().detach().numpy()
        tmp_mask: npt.NDArray[np.float32] = data[0]
        tmp_mask = (tmp_mask > MASK_THRESHOLD).astype(np.float32)
        tmp_mask = np.array(cv2.resize(
            tmp_mask,
            (DSIZE, DSIZE),
            interpolation=cv2.INTER_NEAREST
        )).astype(np.float32)

        mask_fl += tmp_mask

    mask_fl = (mask_fl > 0.5).astype(np.float32)

    # dilate
    for _ in range(5):
        mask_fl = cv2.GaussianBlur(mask_fl, (21, 21), 0)
        mask_fl = (mask_fl > 0.15).astype(np.float32)

    # gaussian_kernel = cv2.GaussianBlur(gaussian_kernel, (21, 21), 0)
    # mask_fl = cv2.dilate(mask_fl, gaussian_kernel, iterations=10)

    mask_arr = np.clip(mask_fl*255, 0, 255).astype(np.uint8)

    output_mask = np.array(cv2.resize(
        mask_arr.astype(np.uint8),
        (image_width, image_height),
        interpolation=cv2.INTER_NEAREST
    )).astype(np.uint8)

    return output_mask


def remove_image_background(image_path, result_path):
    read_img = cv2.imread(image_path)
    mask_img = inference(read_img)
    
    h, w = read_img.shape[:2]
    mask_img = cv2.resize(mask_img, (w, h), interpolation=cv2.INTER_NEAREST)
    
    # print(f"read_img.shape: {read_img.shape[:2]}")
    # print(f"mask_img: {mask_img.shape}")
    
    _, mask_img = cv2.threshold(mask_img, 127, 255, cv2.THRESH_BINARY)
    
    mask_3channel = cv2.merge([mask_img, mask_img, mask_img])
    
    result = cv2.bitwise_and(read_img, mask_3channel)
    
    cv2.imwrite(result_path, result)

# Normalize extensions and make them lower case
extensions = ['.jpg', '.jpeg', '.png', '.dng', '.tiff', '.tif']

# Use a set to avoid duplicates
matching_files = set()

for ext in extensions:
    matching_files.update(
        file for file in input_folder.glob(f'*{ext}')
        if file.suffix.lower() == ext
    )

# Convert set to list if needed
matching_files = list(matching_files)

print(f"Number of matching files: {len(matching_files)}")
print(f"Matching files: {matching_files}")

total_images = len(matching_files)
processed_images = 0

print("Removing Images Background...")

for file in matching_files:
    try:
        input_path = str(file)
        read_img = cv2.imread(input_path)
        mask_img = inference(read_img)
        
        h, w = read_img.shape[:2]
        mask_img = cv2.resize(mask_img, (w, h), interpolation=cv2.INTER_NEAREST)
        _, mask_img = cv2.threshold(mask_img, 127, 255, cv2.THRESH_BINARY)
        mask_3channel = cv2.merge([mask_img, mask_img, mask_img])
        rembg_result = cv2.bitwise_and(read_img, mask_3channel)
        output_path = str(output_folder / (file.stem + "_rembg" + file.suffix))
        
        cv2.imwrite(output_path, rembg_result)
        processed_images += 1
        print(f"Cropped {file.name} ({processed_images}/{total_images})")
        
    except Exception as e:
        print(f"Error processing {file.name}: {e}")
    continue

print("Finished!")