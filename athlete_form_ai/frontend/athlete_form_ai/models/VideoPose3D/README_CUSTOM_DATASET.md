# Custom Dataset for Track Athlete Analysis

This directory contains a modified version of VideoPose3D that supports custom datasets for track athlete analysis with single-camera recordings.

## Features

- **Single Camera Support**: Works with one camera recording (no need for multiple angles)
- **16-Joint Skeleton**: Custom skeleton mapping from MediaPipe to H36M format
- **Track Athlete Optimized**: Designed for analyzing running, jumping, and other track events
- **Visualization**: Generate animated GIFs of 3D pose reconstructions

## Data Structure

### 2D Data (`data_2d_custom_custom.npz`)
```python
{
    "positions_2d": {
        "S1": {  # Subject ID
            "custom": [  # Action name
                # Array of shape (frames, 16, 2) - 2D keypoints
            ]
        }
    },
    "metadata": {
        "layout": "custom",
        "layout_name": "custom",
        "num_joints": 16,
        "keypoints_symmetry": [[0, 3, 6, 9, 12, 15], [1, 4, 7, 10, 13, 14]],
        "video_metadata": {
            "S1": {"w": 1920, "h": 1080}
        }
    }
}
```

### 3D Data (`data_3d_custom.npz`)
```python
{
    "positions_3d": {
        "S1": {  # Subject ID
            "custom": [  # Action name
                # Array of shape (frames, 16, 3) - 3D keypoints
            ]
        }
    }
}
```

## Joint Mapping (MediaPipe → H36M)

The 16 joints are mapped as follows:
```
0: left hip
1: left knee  
2: left ankle
3: right hip
4: right knee
5: right ankle
6: left shoulder
7: left elbow
8: left wrist
9: right shoulder
10: right elbow
11: right wrist
12: pelvis
13: shoulder
14: neck
15: head
```

## Usage

### Training
```bash
python run.py --dataset custom --keypoints custom \
    --subjects-train S1 --subjects-test S1 \
    --epochs 60 --batch-size 1024
```

### Evaluation
```bash
python run.py --dataset custom --keypoints custom \
    --subjects-train S1 --subjects-test S1 \
    --evaluate checkpoint/epoch_60.bin
```

### Visualization
```bash
python run.py --dataset custom --keypoints custom \
    --subjects-train S1 --subjects-test S1 \
    --render --viz-subject S1 --viz-action custom \
    --viz-camera 0 --viz-output output.gif
```

## Data Preparation

Use the script in `../../scripts/prepare_for_videopose3d.py` to convert your MediaPipe 2D keypoints to the required format.

## Customization

- **Skeleton**: Modify `common/custom_dataset.py` to change joint mapping
- **Camera Parameters**: Update camera settings in the custom dataset class
- **Joint Symmetry**: Adjust left/right joint lists for your specific needs

## Notes

- The system works with single-camera recordings
- 3D ground truth is optional (can use dummy data for training)
- Visualization requires proper metadata with `layout_name`
- FPS is set to 30 by default for visualization 