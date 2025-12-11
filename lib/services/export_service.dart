import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../widgets/professional_dialogs.dart';
import 'package:flutter/material.dart';

/// Service untuk export data ke Excel dan PDF
class ExportService {
  /// Export laporan kehadiran ke Excel
  static Future<void> exportToExcel({
    required BuildContext context,
    required List<AttendanceModel> attendanceList,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      excel.delete('Sheet1'); // Delete default sheet
      final sheet = excel['Laporan Kehadiran'];

      // Header row
      sheet.appendRow([
        TextCellValue('No'),
        TextCellValue('Tanggal'),
        TextCellValue('Nama Guru'),
        TextCellValue('NIP'),
        TextCellValue('Ruangan'),
        TextCellValue('Waktu Scan'),
        TextCellValue('Tipe Scan'),
        TextCellValue('Status'),
        TextCellValue('Keterlambatan (menit)'),
      ]);

      // Style header
      final headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('2E7D32'),
        fontColorHex: ExcelColor.fromHexString('FFFFFF'),
        bold: true,
      );

      for (var cell in sheet.rows[0]) {
        cell?.cellStyle = headerStyle;
      }

      // Data rows
      int rowIndex = 1;
      for (var attendance in attendanceList) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        final timeFormat = DateFormat('HH:mm:ss');

        sheet.appendRow([
          TextCellValue(rowIndex.toString()),
          TextCellValue(dateFormat.format(attendance.scanTime)),
          TextCellValue(attendance.teacher?.fullName ?? '-'),
          TextCellValue(attendance.teacher?.nip ?? '-'),
          TextCellValue(attendance.classroom?.name ?? '-'),
          TextCellValue(timeFormat.format(attendance.scanTime)),
          TextCellValue(attendance.scanTypeLabel),
          TextCellValue(attendance.statusLabel),
          TextCellValue(
            attendance.lateMinutes != null ? attendance.lateMinutes.toString() : '-',
          ),
        ]);

        // Style status column
        final statusCell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: 7,
          rowIndex: rowIndex,
        ));
        if (attendance.isOnTime) {
          statusCell?.cellStyle = CellStyle(
            fontColorHex: ExcelColor.fromHexString('43A047'),
            bold: true,
          );
        } else if (attendance.isLate) {
          statusCell?.cellStyle = CellStyle(
            fontColorHex: ExcelColor.fromHexString('FFB300'),
            bold: true,
          );
        }

        rowIndex++;
      }

      // Auto-size columns
      for (var i = 0; i < 9; i++) {
        sheet.setColumnWidth(i, 15.0);
      }

      // Save file
      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('Gagal membuat file Excel');
      }

      // Get save location
      String? outputFile;
      if (kIsWeb) {
        // For web, use download
        throw Exception('Export Excel di web belum didukung. Gunakan PDF.');
      } else {
        // For mobile, save to downloads
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'Laporan_Kehadiran_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.xlsx';
        outputFile = '${directory.path}/$fileName';
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }

      if (context.mounted) {
        ProfessionalDialogs.showSuccessDialog(
          context: context,
          title: 'Export Berhasil',
          message: 'File Excel berhasil disimpan di: $outputFile',
          buttonText: 'OK',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ProfessionalDialogs.showErrorDialog(
          context: context,
          title: 'Export Gagal',
          message: 'Terjadi kesalahan saat export Excel: ${e.toString()}',
        );
      }
    }
  }

  /// Export laporan kehadiran ke PDF
  static Future<void> exportToPDF({
    required BuildContext context,
    required List<AttendanceModel> attendanceList,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
      final timeFormat = DateFormat('HH:mm:ss');

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LAPORAN KEHADIRAN GURU',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#2E7D32'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'SIGAP - Sistem Informasi Guru & Absensi Pegawai',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#2E7D32'),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'PDF',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Period Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E8F5E9'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Icon(
                      pw.IconData(0xe916), // calendar icon
                      size: 16,
                      color: PdfColor.fromHex('#2E7D32'),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Periode: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2E7D32'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('Total', attendanceList.length.toString(), PdfColor.fromHex('#1E88E5')),
                  _buildStatBox(
                    'Tepat Waktu',
                    attendanceList.where((a) => a.isOnTime).length.toString(),
                    PdfColor.fromHex('#43A047'),
                  ),
                  _buildStatBox(
                    'Terlambat',
                    attendanceList.where((a) => a.isLate).length.toString(),
                    PdfColor.fromHex('#FFB300'),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table Header
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#2E7D32'),
                    ),
                    children: [
                      _buildTableCell('No', isHeader: true),
                      _buildTableCell('Tanggal', isHeader: true),
                      _buildTableCell('Nama Guru', isHeader: true),
                      _buildTableCell('Ruangan', isHeader: true),
                      _buildTableCell('Waktu', isHeader: true),
                      _buildTableCell('Status', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...attendanceList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final attendance = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell('${index + 1}'),
                        _buildTableCell(dateFormat.format(attendance.scanTime)),
                        _buildTableCell(attendance.teacher?.fullName ?? '-'),
                        _buildTableCell(attendance.classroom?.name ?? '-'),
                        _buildTableCell(timeFormat.format(attendance.scanTime)),
                        _buildTableCell(
                          attendance.statusLabel,
                          color: attendance.isOnTime
                              ? PdfColor.fromHex('#43A047')
                              : attendance.isLate
                                  ? PdfColor.fromHex('#FFB300')
                                  : PdfColors.blue,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 30),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Dicetak pada: ${dateFormat.format(DateTime.now())} ${timeFormat.format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ];
          },
        ),
      );

      // Show PDF preview and allow sharing
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ProfessionalDialogs.showErrorDialog(
          context: context,
          title: 'Export Gagal',
          message: 'Terjadi kesalahan saat export PDF: ${e.toString()}',
        );
      }
    }
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    // Use a very light grey background instead of trying to lighten the color
    // PdfColor doesn't expose r, g, b properties directly
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader
              ? PdfColors.white
              : color ?? PdfColors.black,
        ),
      ),
    );
  }
}

