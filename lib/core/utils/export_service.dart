import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<String> exportToCsv(
    List<List<dynamic>> data,
    List<String> headers,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(filePath);

    // Ajouter les en-têtes et les données
    final csvData = [headers, ...data];
    final csvContent = csv.encode(csvData);
    await file.writeAsString(csvContent);

    return filePath;
  }

  static Future<void> shareFile(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: 'Export de données PharmaConnect',
      ),
    );
  }

  static Future<void> exportStockReport(
    List<Map<String, dynamic>> stockData,
  ) async {
    final headers = ['Produit', 'DCI', 'Stock', 'Prix', 'Statut'];
    final rows = stockData
        .map(
          (item) => [
            item['name'] ?? '',
            item['genericName'] ?? '',
            item['stock'] ?? 0,
            item['price'] ?? 0,
            item['status'] ?? 'Inconnu',
          ],
        )
        .toList();

    final path = await exportToCsv(rows, headers);
    await shareFile(path);
  }
}
