# Project Agents & Architecture - My Recipe

## 1. Vision Processing Agent (OpenCV)
* **Role:** Handle raw image data to make it machine-readable.
* **Capabilities:** * Perspective Correction (Document scanning).
    * Image Enhancement (Adaptive thresholding for text).
    * Noise Reduction (Gaussian Blur).
* **Tech Stack:** `opencv_dart` for native processing.
* **Rule:** Always process images in a separate `Isolate` or using `compute()` to prevent UI freezing.

## 2. Recipe Extraction Agent
* **Role:** Convert visual information into structured recipe data.
* **Capabilities:** * OCR (Optical Character Recognition) to extract Dish Names and Ingredients.
    * Parser to separate "Quantity" from "Ingredient Name".
* **Tech Stack:** Google ML Kit Text Recognition.

## 3. UI/UX Agent
* **Role:** Maintain a high-quality, "Gallary-style" recipe interface.
* **Goal:** Aesthetic, warm, and easy to use.