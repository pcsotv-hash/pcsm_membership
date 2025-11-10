import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  Future<String> _createPdf(Map<String,dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) {
          return pw.Stack(children: [
            pw.Positioned.fill(child: pw.Center(child: pw.Text(AppConstants.watermarkText, style: const pw.TextStyle(fontSize: 18)))),
            pw.Container(padding: const pw.EdgeInsets.all(20), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("PCSM Membership Card", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height:12),
              pw.Text("Name: ${data['name'] ?? ''}"),
              pw.Text("CNIC: ${data['cnic'] ?? ''}"),
              pw.Text("ID: ${data['id'] ?? ''}"),
              pw.SizedBox(height:8),
              pw.Text("Contact: ${AppConstants.contactPhone}"),
              pw.Text("Website: ${AppConstants.contactWebsite}"),
            ]))
          ]);
        }
      )
    );

    final out = await getTemporaryDirectory();
    final file = File('${out.path}/pcsm_membership_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String,dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String,dynamic>? ?? {};
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("Submission Successful")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Form submitted successfully!", style: TextStyle(fontSize:18)),
              const SizedBox(height:14),
              ElevatedButton(
                onPressed: () async {
                  final path = await _createPdf(args);
                  await Printing.sharePdf(bytes: await File(path).readAsBytes(), filename: "pcsm_membership.pdf");
                },
                child: const Text("Download Membership Card (PDF)"),
              ),
              const SizedBox(height:10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/downloads');
                },
                child: const Text("Downloads & Manshoor"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
