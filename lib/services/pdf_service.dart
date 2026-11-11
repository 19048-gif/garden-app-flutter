import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../main.dart';
import '../models.dart';

class PdfService {
  PdfService._();

  /// Carrega a fonte Roboto com suporte total a UTF-8 / símbolo do Euro (€) e acentos
  static Future<pw.ThemeData> _loadPdfTheme() async {
    try {
      final fontRegular = await PdfGoogleFonts.robotoRegular().timeout(const Duration(seconds: 3));
      final fontBold = await PdfGoogleFonts.robotoBold().timeout(const Duration(seconds: 3));
      return pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      );
    } catch (_) {
      // Fallback em caso de falha de rede/offline
      return pw.ThemeData.base();
    }
  }

  /// Gera os bytes do documento PDF do comprovativo de serviço
  static Future<Uint8List> generateReceiptPdfBytes({
    required Service service,
    required Client client,
  }) async {
    final pdf = pw.Document();
    final theme = await _loadPdfTheme();

    pw.MemoryImage? imgBefore;
    pw.MemoryImage? imgAfter;

    if (service.photoBeforePath != null && File(service.photoBeforePath!).existsSync()) {
      final bytes = await File(service.photoBeforePath!).readAsBytes();
      imgBefore = pw.MemoryImage(bytes);
    }

    if (service.photoAfterPath != null && File(service.photoAfterPath!).existsSync()) {
      final bytes = await File(service.photoAfterPath!).readAsBytes();
      imgAfter = pw.MemoryImage(bytes);
    } else if (service.photoPath != null && File(service.photoPath!).existsSync() && imgBefore == null) {
      final bytes = await File(service.photoPath!).readAsBytes();
      imgAfter = pw.MemoryImage(bytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1B3D2F'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'GardenApp',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Comprovativo de Serviço de Jardinagem',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#4CAF82'),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Data: ${fmtDate(service.date)}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Dados do Cliente
                pw.Text('Dados do Cliente',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),
                pw.Text('Nome: ${client.name}', style: const pw.TextStyle(fontSize: 14)),
                if (client.phone.isNotEmpty)
                  pw.Text('Contacto: ${client.phone}', style: const pw.TextStyle(fontSize: 12)),
                if (client.address.isNotEmpty)
                  pw.Text('Morada: ${client.address}', style: const pw.TextStyle(fontSize: 12)),

                pw.SizedBox(height: 20),

                // Detalhes do Serviço
                pw.Text('Detalhes do Serviço',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tipo de Serviço:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(service.type),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Data & Hora:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${fmtDate(service.date)} às ${fmtTime(service.date)}'),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Estado:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(service.done ? 'Concluído' : 'Pendente'),
                  ],
                ),

                if (service.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('Observações / Notas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(service.notes, style: const pw.TextStyle(fontSize: 11)),
                ],

                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Valor Total:',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        fmtCurrency(service.price),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1B3D2F'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fotos Antes / Depois
                if (imgBefore != null || imgAfter != null) ...[
                  pw.SizedBox(height: 24),
                  pw.Text('Registo Fotográfico',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      if (imgBefore != null)
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text('Antes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 4),
                              pw.Image(imgBefore, height: 140, fit: pw.BoxFit.cover),
                            ],
                          ),
                        ),
                      if (imgBefore != null && imgAfter != null) pw.SizedBox(width: 12),
                      if (imgAfter != null)
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text('Depois', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 4),
                              pw.Image(imgAfter, height: 140, fit: pw.BoxFit.cover),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],

                pw.Spacer(),

                // Rodapé
                pw.Center(
                  child: pw.Text(
                    'Obrigado pela preferência! — GardenApp © ${DateTime.now().year}',
                    style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Exibe menu interativo com opções de Imprimir / Fotocópia, Partilhar e Visualizar PDF
  static Future<void> generateAndShareReceipt({
    required Service service,
    required Client client,
    BuildContext? context,
  }) async {
    final pdfBytes = await generateReceiptPdfBytes(service: service, client: client);
    final filename = 'Comprovativo_${client.name.replaceAll(' ', '_')}_${fmtDate(service.date).replaceAll('/', '-')}.pdf';

    if (context == null) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comprovativo PDF · ${service.type}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Cliente: ${client.name} (${fmtCurrency(service.price)})',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.print, color: gardenForest, size: 26),
              title: const Text('🖨️ Imprimir / Tirar Fotocópia (Impressora)'),
              subtitle: const Text('Envia diretamente para a impressora Wi-Fi ou sistema de impressão'),
              onTap: () {
                Navigator.pop(ctx);
                Printing.layoutPdf(
                  onLayout: (format) async => pdfBytes,
                  name: filename,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue, size: 26),
              title: const Text('📲 Partilhar Ficheiro PDF'),
              subtitle: const Text('Enviar via WhatsApp, Email ou Guardar nos Ficheiros'),
              onTap: () {
                Navigator.pop(ctx);
                Printing.sharePdf(
                  bytes: pdfBytes,
                  filename: filename,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: gardenGreen, size: 26),
              title: const Text('👁️ Visualizar Comprovativo em Ecrã Inteiro'),
              subtitle: const Text('Abrir pré-visualização completa no ecrã'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text('Comprovativo - ${client.name}')),
                      body: PdfPreview(
                        build: (format) => pdfBytes,
                        allowPrinting: true,
                        allowSharing: true,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        pdfFileName: filename,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Gera PDF da Tabela de Preços Completa para Impressão/Fotocópia
  static Future<void> generateAndPrintPriceList(BuildContext context) async {
    final pdf = pw.Document();
    final theme = await _loadPdfTheme();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1B3D2F'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GardenApp',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Tabela Oficial de Preços de Serviços de Jardinagem',
                        style: pw.TextStyle(color: PdfColor.fromHex('#4CAF82'), fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Ano ${DateTime.now().year}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Serviço / Trabalho', 'Categoria', 'Preço Indicativo', 'Unidade / Base'],
              data: [
                for (final item in priceTableCatalog)
                  [item.title, item.category, item.price, item.unit],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1B3D2F')),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerLeft,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Tabela de preços meramente indicativa. Contacte-nos para orçamentos personalizados. — GardenApp © ${DateTime.now().year}',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tabela de Preços em PDF',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.print, color: gardenForest, size: 26),
              title: const Text('🖨️ Imprimir / Tirar Fotocópia da Tabela'),
              onTap: () {
                Navigator.pop(ctx);
                Printing.layoutPdf(
                  onLayout: (format) async => bytes,
                  name: 'Tabela_Precos_GardenApp.pdf',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue, size: 26),
              title: const Text('📲 Partilhar Ficheiro PDF da Tabela'),
              onTap: () {
                Navigator.pop(ctx);
                Printing.sharePdf(bytes: bytes, filename: 'Tabela_Precos_GardenApp.pdf');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
