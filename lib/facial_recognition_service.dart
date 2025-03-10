import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class FacialRecognitionService {
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector();

  // Método para detectar rostros en una imagen
  Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  // Método para guardar los datos faciales
  Future<String> saveFacialData(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = basename(imageFile.path);
    final savedImage = await imageFile.copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  // Método para comparar rostros
  Future<bool> compareFaces(File imageFile1, File imageFile2) async {
    final image1 = decodeImage(await imageFile1.readAsBytes());
    final image2 = decodeImage(await imageFile2.readAsBytes());

    if (image1 == null || image2 == null) return false;

    // Comparar las imágenes (esto es un ejemplo básico)
    final difference = _calculateImageDifference(image1, image2);
    return difference < 0.1; // Umbral de similitud
  }

  // Método para calcular la diferencia entre dos imágenes
  double _calculateImageDifference(Image image1, Image image2) {
    if (image1.width != image2.width || image1.height != image2.height) {
      return 1.0; // Las imágenes tienen dimensiones diferentes
    }

    double difference = 0.0;
    for (int y = 0; y < image1.height; y++) {
      for (int x = 0; x < image1.width; x++) {
        final pixel1 = image1.getPixel(x, y);
        final pixel2 = image2.getPixel(x, y);
        difference += _calculatePixelDifference(pixel1, pixel2);
      }
    }

    return difference / (image1.width * image1.height);
  }

  // Método para calcular la diferencia entre dos píxeles
  double _calculatePixelDifference(int pixel1, int pixel2) {
    final r1 = getRed(pixel1);
    final g1 = getGreen(pixel1);
    final b1 = getBlue(pixel1);
    final r2 = getRed(pixel2);
    final g2 = getGreen(pixel2);
    final b2 = getBlue(pixel2);

    final diffRed = (r1 - r2).abs();
    final diffGreen = (g1 - g2).abs();
    final diffBlue = (b1 - b2).abs();

    return (diffRed + diffGreen + diffBlue) / (3 * 255);
  }
}
