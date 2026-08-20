import 'package:flutter/material.dart';

void mostrarAviso(BuildContext context, String mensaje, {bool esError = false}) {
  final colores = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: esError ? colores.onErrorContainer : null,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style:
                    esError ? TextStyle(color: colores.onErrorContainer) : null,
              ),
            ),
          ],
        ),
        backgroundColor: esError ? colores.errorContainer : null,
        duration: Duration(seconds: esError ? 6 : 3),
      ),
    );
}
