import os
import random

pth_dir = "/workspace/data/pointclouds"
split_dir = "/workspace/data/splits"
os.makedirs(split_dir, exist_ok=True)

# Get all .pth files and strip the extension
all_files = [f[:-4] for f in os.listdir(pth_dir) if f.endswith(".pth")]
all_files.sort()
random.seed(42)
random.shuffle(all_files)

# 75% train, 25% val split
split_idx = int(0.75 * len(all_files))
train_files = all_files[:split_idx]
val_files = all_files[split_idx:]

with open(os.path.join(split_dir, "train.txt"), "w") as f:
    f.write("\n".join(train_files))

with open(os.path.join(split_dir, "val.txt"), "w") as f:
    f.write("\n".join(val_files))

print(f"✅ Wrote {len(train_files)} train and {len(val_files)} val entries.")