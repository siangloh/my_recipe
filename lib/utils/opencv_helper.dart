
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

// Top-level function for isolate compatibility, as required by Rules.md
Future<Uint8List> processImageForRecipe(Uint8List imageData) async {
  return OpenCVHelper.processRecipeImage(imageData);
}

class OpenCVHelper {
  // Processes an image using the pipeline defined in Rules.md.
  static Uint8List processRecipeImage(Uint8List imageData) {
    // 1. Decode the image data into an OpenCV Mat
    final cv.Mat image = cv.imdecode(imageData, cv.IMREAD_COLOR);
    if (image.isEmpty) {
      throw Exception("Failed to decode image");
    }

    // 2. Convert the image to grayscale
    final cv.Mat gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);

    // 3. Apply Gaussian Blur to reduce noise before edge detection
    final cv.Mat blurred = cv.gaussianBlur(gray, (5, 5), 0);

    // 4. Apply Canny Edge Detection
    // The thresholds (100, 200) can be tuned for better results.
    final cv.Mat edges = cv.canny(blurred, 100, 200);

    // 5. Encode the processed Mat back to a Uint8List (as PNG)
    // cv.imencode returns a record (bool, Uint8List)
    final (bool success, Uint8List processedData) = cv.imencode('.png', edges);
    if (!success) {
      // Clean up before throwing an exception
      image.dispose();
      gray.dispose();
      blurred.dispose();
      edges.dispose();
      throw Exception("Failed to encode processed image");
    }

    // 6. Release memory for all Mat objects to prevent leaks
    image.dispose();
    gray.dispose();
    blurred.dispose();
    edges.dispose();

    return processedData;
  }
}
