# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

import numpy as np
import copy
import os
from common.skeleton import Skeleton
from common.mocap_dataset import MocapDataset
from common.camera import normalize_screen_coordinates, image_coordinates
from common.h36m_dataset import h36m_skeleton
       

custom_camera_params = {
    'id': None,
    'res_w': None, # Pulled from metadata
    'res_h': None, # Pulled from metadata
    
    # Dummy camera parameters (taken from Human3.6M), only for visualization purposes
    'azimuth': 70, # Only used for visualization
    'orientation': [0.1407056450843811, -0.1500701755285263, -0.755240797996521, 0.6223280429840088],
    'translation': [1841.1070556640625, 4955.28466796875, 1563.4454345703125],
}

# Custom skeleton for 16 joints (mapped from MediaPipe to H36M format)
custom_skeleton = Skeleton(
    parents=[
        12,  # 0: left hip      -> pelvis
        0,   # 1: left knee     -> left hip
        1,   # 2: left ankle    -> left knee
        12,  # 3: right hip     -> pelvis
        3,   # 4: right knee    -> right hip
        4,   # 5: right ankle   -> right knee
        13,  # 6: left shoulder -> shoulder
        6,   # 7: left elbow    -> left shoulder
        7,   # 8: left wrist    -> left elbow
        13,  # 9: right shoulder-> shoulder
        9,   #10: right elbow   -> right shoulder
        10,  #11: right wrist   -> right elbow
        -1,  #12: pelvis        -> root
        12,  #13: shoulder      -> pelvis
        13,  #14: neck          -> shoulder
        14   #15: head          -> neck
    ],
    joints_left=[0, 1, 2, 6, 7, 8],
    joints_right=[3, 4, 5, 9, 10, 11]
)

class CustomDataset(MocapDataset):
    def __init__(self, detections_path, remove_static_joints=True):
        super().__init__(fps=None, skeleton=custom_skeleton)  # Use custom skeleton
        
        # Load serialized dataset
        data = np.load(detections_path, allow_pickle=True)
        resolutions = data['metadata'].item()['video_metadata']
        
        self._cameras = {}
        self._data = {}
        for video_name, res in resolutions.items():
            cam = {}
            cam.update(custom_camera_params)
            cam['orientation'] = np.array(cam['orientation'], dtype='float32')
            cam['translation'] = np.array(cam['translation'], dtype='float32')
            cam['translation'] = cam['translation']/1000 # mm to meters
            
            cam['id'] = video_name
            cam['res_w'] = res['w']
            cam['res_h'] = res['h']
            
            self._cameras[video_name] = [cam]
        
            self._data[video_name] = {
                'custom': {
                    'cameras': [cam]  # Make it a list of cameras
                }
            }
        
        # Load 3D data if available
        detections_dir = os.path.dirname(detections_path)
        detections_name = os.path.basename(detections_path)
        # Extract dataset name from path like "data_2d_custom_custom.npz"
        dataset_name = detections_name.split('_')[2]  # "custom"
        data_3d_path = os.path.join(detections_dir, f'data_3d_{dataset_name}.npz')
        
        if os.path.exists(data_3d_path):
            print(f"Loading 3D data from {data_3d_path}")
            data_3d = np.load(data_3d_path, allow_pickle=True)
            positions_3d = data_3d['positions_3d'].item()
            
            # Add 3D data to the dataset
            for subject in positions_3d.keys():
                if subject in self._data:
                    for action in positions_3d[subject].keys():
                        if action in self._data[subject]:
                            self._data[subject][action]['positions_3d'] = positions_3d[subject][action]
        else:
            print(f"3D data file not found: {data_3d_path}")
                
        # Remove or comment out the following line for custom skeletons:
        # self.remove_joints([4, 5, 9, 10, 11, 16, 20, 21, 22, 23, 24, 28, 29, 30, 31])
   
    def supports_semi_supervised(self):
        return False
        
    def fps(self):
        """Return the FPS for visualization purposes."""
        return 30  # Default FPS for custom videos
   