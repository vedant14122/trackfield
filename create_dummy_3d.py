# create_dummy_3d.py
import numpy as np

# Creates an empty "positions_3d" dict just to satisfy the loader because stupid python is trash as shit
dummy = {
    "S1": {}
}
np.savez("data/data_3d_h36m.npz", positions_3d=dummy)

print("✅ Created dummy 3D file: data/data_3d_h36m.npz")
