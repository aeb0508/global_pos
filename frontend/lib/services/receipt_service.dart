import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/receipt.dart';
import '../providers/app_settings_provider.dart';

class ReceiptService {
  static const String companyName = 'Global POS';
  static const String companyAddress = '123 Business Street, City, Country';
  static const String companyPhone = '+1 234 567 8900';
  static const String companyEmail = 'info@globalpos.com';

  static Future<void> printReceipt(
      Receipt receipt, BuildContext context) async {
    final sym = context.read<AppSettingsProvider>().currencySymbol;
    final pdf = await generateReceiptPdf(receipt, sym);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> previewReceipt(
      Receipt receipt, BuildContext context) async {
    final sym = context.read<AppSettingsProvider>().currencySymbol;
    final pdf = await generateReceiptPdf(receipt, sym);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Receipt Preview')),
          body: PdfPreview(build: (format) async => pdf.save()),
        ),
      ),
    );
  }

  static Future<pw.Document> generateReceiptPdf(
      Receipt receipt, String currencySymbol) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Company Header
              pw.Text(
                companyName,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(companyPhone, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(companyEmail, style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Receipt Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt #:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(receipt.orderNumber),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatDateTime(receipt.date)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cashier:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(receipt.cashierName),
                ],
              ),
              if (receipt.customerName != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(receipt.customerName!),
                  ],
                ),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Items
              ...receipt.items.map((item) => pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text(item.name)),
                          pw.Text('${item.total.toStringAsFixed(2)} $currencySymbol'),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            '  ${item.quantity} x ${item.price.toStringAsFixed(2)} $currencySymbol',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                    ],
                  )),
              pw.Divider(),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('${receipt.subtotal.toStringAsFixed(2)} $currencySymbol'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax:'),
                  pw.Text('${receipt.tax.toStringAsFixed(2)} $currencySymbol'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${receipt.total.toStringAsFixed(2)} $currencySymbol',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment (${receipt.paymentMethod}):'),
                  pw.Text('${receipt.amountPaid.toStringAsFixed(2)} $currencySymbol'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change:'),
                  pw.Text('${receipt.change.toStringAsFixed(2)} $currencySymbol'),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),

              // Footer
              pw.Text('Thank you for your business!',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Please come again',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),

              // Barcode
              pw.BarcodeWidget(
                data: receipt.orderNumber,
                barcode: pw.Barcode.code128(),
                width: 150,
                height: 40,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
