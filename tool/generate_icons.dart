import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  File file = File('imagenes/icono_app.png');
  if (!file.existsSync()) {
    file = File('imagenes/icono_app.jpeg');
  }

  if (!file.existsSync()) {
    print('No se encontro el archivo imagenes/icono_app');
    return;
  }

  print('Procesando icono oficial desde: ${file.path}');
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('No se pudo decodificar la imagen');
    return;
  }

  print('Dimensiones originales: ${image.width}x${image.height}');

  final densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in densities.entries) {
    final density = entry.key;
    final size = entry.value;

    final resized = img.copyResize(image, width: size, height: size);

    // Guardar ic_launcher.png
    final standardPath = 'android/app/src/main/res/$density/ic_launcher.png';
    final outFile = File(standardPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(resized));

    // Guardar ic_launcher_round.png para launchers que admiten icono circular
    final roundPath = 'android/app/src/main/res/$density/ic_launcher_round.png';
    final outRoundFile = File(roundPath);
    outRoundFile.writeAsBytesSync(img.encodePng(resized));

    print('Generado $density (${size}x$size)');
  }

  print('¡Iconos oficiales de la aplicacion PTAP configurados con exito!');
}
