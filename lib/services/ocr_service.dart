import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/voucher.dart';
import 'package:intl/intl.dart';

class OcrService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    return recognizedText.text;
  }

  Future<VoucherExtractionResult> extractVoucherDetails(File imageFile) async {
    try {
      final extractedText = await extractText(imageFile);
      return _parseVoucherDetails(extractedText);
    } catch (e) {
      return VoucherExtractionResult(
        success: false,
        errorMessage: 'Failed to process image: ${e.toString()}',
      );
    }
  }

  VoucherExtractionResult _parseVoucherDetails(String text) {
    // Convert text to lowercase for easier matching
    final lowerText = text.toLowerCase();
    
    // Default values
    String code = '';
    String store = '';
    String description = '';
    double discountAmount = 0.0;
    String discountType = 'percentage';
    DateTime? expiryDate;
    
    // Try to extract coupon/voucher code
    final codePatterns = [
      RegExp(r'code[:\s]+([A-Za-z0-9]+)'),
      RegExp(r'coupon[:\s]+([A-Za-z0-9]+)'),
      RegExp(r'voucher[:\s]+([A-Za-z0-9]+)'),
      RegExp(r'promo[:\s]+([A-Za-z0-9]+)'),
    ];
    
    for (final pattern in codePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        code = match.group(1)!.toUpperCase();
        break;
      }
    }
    
    // Extract discount amount
    final discountPatterns = [
      RegExp(r'(\d+)%\s+off'),
      RegExp(r'(\d+)%\s+discount'),
      RegExp(r'save\s+(\d+)%'),
      RegExp(r'\$(\d+(\.\d{1,2})?)\s+off'),
    ];
    
    for (final pattern in discountPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        final value = match.group(1)!;
        if (pattern.pattern.contains(r'%')) {
          discountAmount = double.tryParse(value) ?? 0.0;
          discountType = 'percentage';
        } else {
          discountAmount = double.tryParse(value) ?? 0.0;
          discountType = 'fixed';
        }
        break;
      }
    }
    
    // Try to extract store name
    final storePatterns = [
      RegExp(r'at\s+([A-Za-z0-9\s]+)'),
      RegExp(r'from\s+([A-Za-z0-9\s]+)'),
      RegExp(r'([A-Za-z0-9\s]+)\s+voucher'),
      RegExp(r'([A-Za-z0-9\s]+)\s+coupon'),
    ];
    
    for (final pattern in storePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        store = match.group(1)!.trim();
        // Capitalize first letter of each word
        store = store.split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
        ).join(' ');
        break;
      }
    }
    
    // Try to extract expiry date
    final datePatterns = [
      RegExp(r'expires?\s+on\s+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'),
      RegExp(r'valid\s+until\s+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'),
      RegExp(r'expires?\s+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'),
      // For dates in MMM DD, YYYY format (e.g., Jan 31, 2023)
      RegExp(r'expires?\s+on\s+([A-Za-z]{3}\s+\d{1,2},?\s+\d{4})'),
      RegExp(r'valid\s+until\s+([A-Za-z]{3}\s+\d{1,2},?\s+\d{4})'),
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        final dateStr = match.group(1)!;
        try {
          if (dateStr.contains('/') || dateStr.contains('-')) {
            // For formats like MM/DD/YYYY or DD/MM/YYYY
            final parts = dateStr.split(RegExp(r'[/-]'));
            if (parts.length == 3) {
              // Assuming MM/DD/YYYY format
              int month = int.parse(parts[0]);
              int day = int.parse(parts[1]);
              int year = int.parse(parts[2]);
              
              // Adjust year if it's a 2-digit year
              if (year < 100) {
                year += 2000;
              }
              
              expiryDate = DateTime(year, month, day);
            }
          } else {
            // For formats like "Jan 31, 2023"
            expiryDate = DateFormat('MMM d, yyyy').parse(dateStr);
          }
        } catch (e) {
          // Continue to next pattern if this one fails
        }
        
        if (expiryDate != null) {
          break;
        }
      }
    }
    
    // If we couldn't extract an expiry date, set a default (30 days from now)
    expiryDate ??= DateTime.now().add(const Duration(days: 30));
    
    // Extract description - use first few words of the text if no better description found
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      // Use the first non-empty line as description if it's not too long
      for (final line in lines) {
        if (line.trim().isNotEmpty && line.length < 100) {
          description = line.trim();
          break;
        }
      }
    }
    
    // If we still don't have a description, create one based on discount
    if (description.isEmpty) {
      if (discountType == 'percentage') {
        description = '${discountAmount.toInt()}% off';
      } else {
        description = '\$${discountAmount.toStringAsFixed(2)} off';
      }
      
      if (store.isNotEmpty) {
        description += ' at $store';
      }
    }
    
    // Use original text if store is still empty
    if (store.isEmpty) {
      store = 'Unknown Store';
    }
    
    // Generate a code if one wasn't found
    if (code.isEmpty) {
      // Create a random-looking code based on store name and discount
      final storePrefix = store.isNotEmpty ? store.replaceAll(' ', '').substring(0, min(3, store.length)).toUpperCase() : 'VCH';
      final discountStr = discountAmount.toInt().toString();
      final randomPart = DateTime.now().millisecondsSinceEpoch.toString().substring(9, 12);
      code = '$storePrefix$discountStr$randomPart';
    }
    
    return VoucherExtractionResult(
      success: true,
      voucher: Voucher(
        code: code,
        description: description,
        store: store,
        discountAmount: discountAmount,
        discountType: discountType,
        expiryDate: expiryDate,
        imageUrl: '',  // Will be set later when the image is saved
      ),
    );
  }
  
  int min(int a, int b) => a < b ? a : b;
  
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

class VoucherExtractionResult {
  final bool success;
  final Voucher? voucher;
  final String errorMessage;
  
  VoucherExtractionResult({
    required this.success,
    this.voucher,
    this.errorMessage = '',
  });
}
