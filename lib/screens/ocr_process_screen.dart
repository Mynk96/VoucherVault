import 'dart:io';
import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../services/ocr_service.dart';

class OcrProcessScreen extends StatefulWidget {
  final File imageFile;
  
  const OcrProcessScreen({
    Key? key,
    required this.imageFile,
  }) : super(key: key);

  @override
  State<OcrProcessScreen> createState() => _OcrProcessScreenState();
}

class _OcrProcessScreenState extends State<OcrProcessScreen> {
  final OcrService _ocrService = OcrService();
  late Future<VoucherExtractionResult> _extractionFuture;
  
  @override
  void initState() {
    super.initState();
    _extractionFuture = _ocrService.extractVoucherDetails(widget.imageFile);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Image'),
      ),
      body: FutureBuilder<VoucherExtractionResult>(
        future: _extractionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (snapshot.hasData) {
            final result = snapshot.data!;
            if (result.success && result.voucher != null) {
              return _buildSuccessState(result.voucher!);
            } else {
              return _buildErrorState(result.errorMessage);
            }
          } else {
            return _buildErrorState('Failed to process image.');
          }
        },
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              widget.imageFile,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Extracting voucher details...',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a moment',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error processing image',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessState(Voucher voucher) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                widget.imageFile,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Extracted Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoRow('Code', voucher.code),
          _buildInfoRow('Store', voucher.store),
          _buildInfoRow('Description', voucher.description),
          _buildInfoRow(
            'Discount',
            voucher.discountType == 'percentage'
                ? '${voucher.discountAmount}%'
                : '\$${voucher.discountAmount}',
          ),
          _buildInfoRow('Expires', voucher.formattedExpiryDate),
          
          const SizedBox(height: 24),
          
          const Text(
            'Does this look correct?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Return the extracted voucher to the previous screen
                    Navigator.pop(context, voucher);
                  },
                  child: const Text('Use This Information'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
