import os
import numpy as np
import torch

# Input and output directories
npz_dir = "/workspace/data/weld_npz"
pth_dir = "/workspace/data/pointclouds"
os.makedirs(pth_dir, exist_ok=True)

for file in os.listdir(npz_dir):
    if file.endswith(".npz"):
        npz_path = os.path.join(npz_dir, file)
        data = np.load(npz_path)

        coord = data["pos"].astype(np.float32)
        label = data["y"].astype(np.int64)

        point_data = {
            "coord": torch.from_numpy(coord),
            "label": torch.from_numpy(label)
        }

        out_name = file.replace(".npz", ".pth")
        out_path = os.path.join(pth_dir, out_name)
        torch.save(point_data, out_path)

        print(f"✅ Converted {file} → {out_name}")