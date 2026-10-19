import 'package:flutter/material.dart';

enum DataImportMode { merge, replace }

class ImportModeDialog {
  static Future<DataImportMode?> show(BuildContext context) {
    return showDialog<DataImportMode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Режим импорта'),
          content: const Text(
            'Выберите способ импорта данных:\n\n'
            '• Объединить (Merge): добавить/обновить существующие записи.\n'
            '• Заменить (Replace): полностью очистить базу данных перед импортом.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, DataImportMode.merge),
              child: const Text('Объединить'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, DataImportMode.replace),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Заменить'),
            ),
          ],
        );
      },
    );
  }
}
