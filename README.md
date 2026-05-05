# Spinal Disc Herniation Image Enhancement and Detection from MRI

> A MATLAB-based biomedical image processing system for the automated enhancement and detection of lumbar spinal disc herniations from MRI scans.

**Institution:** Al Andalus University for Medical Sciences — College of Biomedical Engineering  
**Authors:** Tareq Zaefa
**Academic Year:** 2022 – 2023  

---

## Table of Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Repository Structure](#repository-structure)
- [Processing Pipeline](#processing-pipeline)
- [Graphical User Interface](#graphical-user-interface)
- [Requirements](#requirements)
- [Usage](#usage)
- [Results](#results)
- [References](#references)

---

## Overview

Lumbar disc herniation is among the most prevalent disorders of the spinal column, often leading to chronic pain, nerve compression, and reduced quality of life. Accurate, early diagnosis is essential for determining an appropriate treatment course — yet manual interpretation of MRI scans remains time-consuming and subject to inter-observer variability.

This project presents an automated image processing pipeline implemented in MATLAB that takes raw MRI scans (in DICOM format) as input and produces a clearly delineated, annotated output highlighting the spinal cord and the precise region of disc herniation. The system reduces reliance on subjective manual analysis and provides a reproducible, computationally consistent segmentation framework suitable for clinical support.

---

## Motivation

The clinical problem driving this work is twofold:

1. **Prevalence**: Lumbar disc herniation is one of the most common pathologies affecting the spinal column, making efficient and scalable diagnostic tools highly valuable.
2. **Diagnostic gap**: Existing segmentation methods for degenerated intervertebral discs lack the precision required to reliably distinguish between disc stages (normal → bulging → protrusion → extrusion) from MRI data alone.

By employing a multi-stage morphological image processing approach, this system assists clinicians by pinpointing the herniation zone directly on the original scan, reducing both diagnostic time and human error.

---

## Repository Structure

```
spinal-disc-herniation-mri/
│
├── src/                          # MATLAB source code
│   ├── rrrrr.m                   # Core image processing function (main pipeline)
│   ├── gui_app.mlapp             # MATLAB App Designer GUI application
│   └── helpers/
│       └── plotObjectsAndBoundaries.m   # Utility: visualize segmented boundaries
│
├── data/                         # Sample MRI data (DICOM format)
│   ├── sample_cases/
│   │   ├── case_01.dcm
│   │   ├── case_02.dcm
│   │   └── ...                   # Additional anonymized clinical cases
│   └── README_data.md            # Data usage and anonymization notes
│
├── results/                      # Output figures from the processing stages
│   ├── stage_01_original.png     # Raw MRI input
│   ├── stage_02_enhanced.png     # After histogram equalization & adjustment
│   ├── stage_03_morphological.png# After morphological reconstruction
│   ├── stage_04_binary.png       # Binary mask
│   ├── stage_05_thresholded.png  # Thresholded product image
│   ├── stage_06_cord_initial.png # Preliminary spinal cord segmentation
│   ├── stage_07_cord_refined.png # Refined cord segmentation
│   ├── stage_08_herniation.png   # Herniation region isolated
│   └── stage_09_annotated.png    # Final annotated overlay on original MRI
│
├── docs/
│   └── thesis.pdf                # Full project thesis (Arabic)
│
└── README.md                     # This file
```

> **Note:** If you have access to the full repository, the structure above reflects the logical organization of the project files. Please update paths as needed to match your local clone.

---

## Processing Pipeline

The algorithm proceeds through nine sequential stages, each building on the output of the previous step. The diagram below summarizes the overall flow:

```
┌─────────────────────┐
│  1. Read MRI Image  │  ← DICOM input via dicomread()
└────────┬────────────┘
         │
         ▼
┌─────────────────────────────┐
│  2. Image Enhancement       │  ← histeq + imadjust + CLAHE (adapthisteq)
└────────┬────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│  3. Morphological Reconstruction │  ← imopen + imerode + imreconstruct
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────┐
│  4. Binarization         │  ← imbinarize (Otsu / fixed threshold)
└────────┬─────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  5. Masking & Adaptive Thresholding│  ← immultiply + pixel-range thresholding
└────────┬───────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  6. Preliminary Spinal Cord Seg.     │  ← imdilate + imfill + bwareaopen
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│  7. Measure Region Properties    │  ← regionprops (Area, Centroid, Solidity…)
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│  8. Full Spinal Cord Isolation   │  ← bwboundaries + conditional refinement
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│  9. Herniation Detection & ROI   │  ← bwperim overlay on original image
└──────────────────────────────────┘
```

### Stage Details

**Stage 1 — Image Reading**  
MRI scans are loaded from DICOM files using MATLAB's `dicomread` and `dicominfo` functions. The pipeline accepts standard grayscale MRI volumes.

**Stage 2 — Image Enhancement**  
Three complementary enhancement operations are applied in sequence. Histogram equalization (`histeq`) redistributes intensity values globally, followed by contrast stretching via `imadjust` targeting the high-intensity range `[0.75, 0.95]`. Finally, Contrast-Limited Adaptive Histogram Equalization (CLAHE) is applied using a Rayleigh distribution and a clip limit of 0.2, ensuring local contrast improvements without amplifying noise.

**Stage 3 — Morphological Reconstruction**  
An opening operation with a disk-shaped structuring element suppresses fine noise while preserving large structures. A morphological marker is then derived by eroding the CLAHE-enhanced image, and `imreconstruct` is applied to recover the dominant structural regions, effectively separating the spinal column tissue from surrounding anatomy.

**Stage 4 — Binarization**  
The reconstructed image is converted to a binary mask using `imbinarize` with a fixed threshold of 0.65, isolating candidate tissue regions.

**Stage 5 — Masking and Adaptive Thresholding**  
The binary mask is multiplied element-wise with the original image to suppress background pixels. A pixel-range-aware thresholding rule is then applied: images with maximum intensity above 800 use a fixed threshold of 650; those between 350 and 800 use 300; all others fall back to Otsu's method via `graythresh`.

**Stage 6 — Preliminary Spinal Cord Segmentation**  
Morphological dilation, complement operations, hole filling, and area filtering (`bwareaopen`, minimum 1600 pixels) are applied to isolate candidate spinal cord objects and remove small spurious regions.

**Stage 7 — Region Property Measurement**  
`regionprops` extracts quantitative descriptors — area, centroid, major/minor axis lengths, eccentricity, convex area, solidity, and pixel lists — from the candidate regions. These measurements drive subsequent conditional logic.

**Stage 8 — Full Spinal Cord Isolation**  
If multiple candidate objects are detected, a linear structuring element at 55° is used to close and open the binary image, and the residual is area-filtered to retain only the spinal cord structure. The cord is then dilated and multiplied against the original image to produce a clean, localized region.

**Stage 9 — Herniation Detection and Annotation**  
A secondary morphological analysis isolates the herniated disc region from the cord mask. The identified herniation boundary is overlaid onto the original MRI using `bwperim`, producing a clinically interpretable annotated image with the region of interest clearly delineated.

---

## Graphical User Interface

The project includes a MATLAB App Designer GUI that wraps the full pipeline into a straightforward three-step interface:

| Button | Action |
|---|---|
| **Load the Image** | Opens a file browser to select a DICOM MRI file |
| **Run the Code Stages** | Executes the full nine-stage processing pipeline |
| **Display the Final Result** | Renders the annotated output image in the main panel |

The GUI is designed to make the tool accessible to clinicians and researchers without requiring familiarity with MATLAB scripting.

---

## Requirements

- **MATLAB** R2018b or later (R2020a+ recommended)
- **Image Processing Toolbox** (required — all core functions depend on it)
- **DICOM-compatible MRI data** (T2-weighted, midsagittal or parasagittal lumbar spine views are recommended)

No additional third-party toolboxes are needed.

---

## Usage

### Running via Script

```matlab
% Load the DICOM image
info = dicominfo('path/to/your/scan.dcm');
img  = dicomread(info);

% Run the full pipeline
rrrrr(img);
```

The function will produce nine labeled figure windows corresponding to each processing stage. The final figure (`Figure 9`) displays the annotated MRI with the herniated disc region highlighted.

### Running via GUI

1. Open MATLAB and navigate to the `src/` directory.
2. Open `gui_app.mlapp` in App Designer (or double-click to launch).
3. Click **Load the Image** and select your DICOM file.
4. Click **Run the Code Stages** to execute the pipeline.
5. Click **Display the Final Result** to view the annotated output.

---

## Results

The pipeline was validated on a set of clinical MRI cases covering a range of lumbar disc pathologies. Key output stages are illustrated below (see `results/` directory for full-resolution figures):

| Stage | Description |
|---|---|
| Figure 1 | Original MRI scan |
| Figure 2 | Enhanced image after histogram equalization and intensity adjustment |
| Figure 3 | Output of morphological reconstruction |
| Figure 4 | Binary mask product |
| Figure 5 | Thresholded image |
| Figure 6 | Preliminary spinal cord segmentation |
| Figure 7 | Refined cord region |
| Figure 8 | Isolated herniation mask |
| Figure 9 | Final annotated overlay on original MRI |

The system successfully isolates the spinal cord and identifies the herniation zone across cases with varying pixel intensity ranges, demonstrating robustness to differences in MRI acquisition parameters.

---

## References

The theoretical foundation and related work reviewed in this project include the following studies:

- Study 2012 — Early morphological segmentation of intervertebral discs from MRI
- Study 2021 — Deep learning approaches for spinal disc degeneration detection
- Study 2022 — Automated lumbar spine segmentation using hybrid morphological methods
- Study 2023 — Recent advances in MRI-based herniation localization

Full bibliographic details are available in the project thesis (`docs/thesis.pdf`).

---


*Al Andalus University for Medical Sciences — College of Biomedical Engineering — 2022/2023*
