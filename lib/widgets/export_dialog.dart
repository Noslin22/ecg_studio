import 'package:flutter/material.dart';

enum ExportFormat { svg, png }

class ExportDialog extends StatelessWidget {
  const ExportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar imagem final'),
      content: const Text('Escolha o formato para salvar o ECG gerado.'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, ExportFormat.svg),
          icon: const Icon(Icons.code),
          label: const Text('SVG'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, ExportFormat.png),
          icon: const Icon(Icons.image_outlined),
          label: const Text('PNG'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
