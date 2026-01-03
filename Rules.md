# Development Rules & UI Standards

## 1. UI & Aesthetic Standards
* **Theme:** Use a "Warm Gourmet" theme.
    * **Background:** `#FBF9F6` (Warm Parchment).
    * **Primary:** `#5D4037` (Dark Brown / Espresso).
    * **Accent:** `#FF9800` (Orange) for CTA (Call to Action) buttons.
* **Shapes:** Use `BorderRadius.circular(24)` for all cards and buttons. No sharp corners.
* **Shadows:** Use subtle shadows: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)`.
* **Feedback:** Every button must have an `InkWell` or `ElevatedButton` ripple effect.

## 2. Coding Standards (English Only)
* **Language:** All code, variable names, class names, and comments MUST be in English.
* **Structure:** * Business logic goes into `lib/services/`.
    * UI components go into `lib/widgets/`.
    * OpenCV wrappers go into `lib/utils/opencv_helper.dart`.
* **State Management:** Use `Provider` or `Riverpod` (User's choice). Default to `StatefulWidget` for simple UI logic.

## 3. OpenCV Integration Rules
* **Input/Output:** Always use `Uint8List` for transferring image data between Dart and OpenCV.
* **Memory:** Ensure `Mat` objects in OpenCV are disposed of to prevent memory leaks in the native heap.
* **Pipeline:** For recipe scanning, use the following sequence:
    1. Grayscale -> 2. GaussianBlur -> 3. Canny Edge Detection -> 4. Find Contours (for crop).

## Video Integration Rules
* **Video Library:** Use `video_player` or `chewie` for playback.
* **Storage:** Video paths should be stored locally (File Path) or via URL.
* **Performance:** Use `flick_video_player` for a better UI/UX if multiple videos are in a list.

## AI Input Rules (Auto-Parsing)
* When scanning text, the system must show a "Review Data" screen before saving.
* User should be able to click on the OCR-detected text to map it to "Ingredient" or "Instruction".