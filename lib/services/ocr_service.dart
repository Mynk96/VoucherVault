import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/voucher.dart';
import 'package:intl/intl.dart';

class OcrService {
  late final TextRecognizer _textRecognizer;
  
  OcrService() {
    _textRecognizer = GoogleMlKit.vision.textRecognizer();
  }

  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Debug output - remove in production
      debugPrint('OCR Raw Text: ${recognizedText.text}');
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR Error: ${e.toString()}');
      rethrow; // Rethrow to be caught by the calling method
    }
  }

  Future<VoucherExtractionResult> extractVoucherDetails(File imageFile) async {
    try {
      // Pre-process the image
      // Note: in a more advanced implementation, we could resize/enhance the image
      
      // Extract text from the image
      final extractedText = await extractText(imageFile);
      
      // If no text was extracted, return an error
      if (extractedText.trim().isEmpty) {
        return VoucherExtractionResult(
          success: false,
          errorMessage: 'No text was found in the image. Please try a clearer image.',
        );
      }
      
      // Parse the extracted text to identify voucher details
      return _parseVoucherDetails(extractedText);
    } catch (e) {
      debugPrint('Voucher extraction error: ${e.toString()}');
      return VoucherExtractionResult(
        success: false,
        errorMessage: 'Failed to process image: ${e.toString()}',
      );
    }
  }

  VoucherExtractionResult _parseVoucherDetails(String text) {
    // Debug the input text
    debugPrint('Parsing text: $text');
    
    // Clean and normalize the text
    // - replace multiple spaces with single space
    // - normalize newlines
    final cleanedText = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();
    
    // Convert text to lowercase for easier matching
    final lowerText = cleanedText.toLowerCase();
    
    // Debug the cleaned text
    debugPrint('Cleaned text: $cleanedText');
    
    // Default values
    String code = '';
    String store = '';
    String description = '';
    double discountAmount = 0.0;
    String discountType = 'percentage';
    DateTime? expiryDate;
    
    // Try to extract coupon/voucher code - enhanced patterns
    final codePatterns = [
      // Standard formats
      RegExp("code[:\\s]+([A-Za-z0-9]+)"),
      RegExp("coupon[:\\s]+([A-Za-z0-9]+)"),
      RegExp("voucher[:\\s]+([A-Za-z0-9]+)"),
      RegExp("promo[:\\s]+([A-Za-z0-9]+)"),
      // Common formats with hyphens
      RegExp("code[:\\s]+([A-Za-z0-9\\-]+)"),
      // Standalone codes that look like promo codes (uppercase with numbers)
      RegExp("\\b([A-Z0-9]{5,12})\\b"),
      // Codes that might be preceded by "use" or "enter"
      RegExp("use\\s+([A-Za-z0-9\\-]+)"),
      RegExp("enter\\s+([A-Za-z0-9\\-]+)"),
      // Codes that are near the "promo" or "discount" words
      RegExp("(promo|discount|offer).*?([A-Z0-9]{5,12})"),
    ];
    
    for (final pattern in codePatterns) {
      final matches = pattern.allMatches(lowerText);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final possibleCode = match.group(1)?.toUpperCase() ?? '';
          
          // Validate the code - should be alphanumeric and reasonable length
          if (possibleCode.length >= 4 && possibleCode.length <= 20) {
            code = possibleCode;
            debugPrint('Found code: $code using pattern: ${pattern.pattern}');
            break;
          }
        }
      }
      if (code.isNotEmpty) break;
    }
    
    // Extract discount amount - simplified approach focusing on percentages
    final discountPatterns = [
      RegExp("(\\d+)%\\s*off"),
      RegExp("(\\d+)%\\s*discount"),
      RegExp("save\\s+(\\d+)%"),
      RegExp("(\\d+)%\\s*savings"),
      // Common discount formats
      RegExp("get\\s+(\\d+)%\\s*off"),
      RegExp("discount\\s*:\\s*(\\d+)%"),
      RegExp("(\\d+)%"),  // Simple percentage (less specific, use last)
    ];
    
    for (final pattern in discountPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        final value = match.group(1) ?? '0';
        if (pattern.pattern.contains("%")) {
          discountAmount = double.tryParse(value) ?? 0.0;
          discountType = 'percentage';
          debugPrint('Found percentage discount: $discountAmount% using pattern: ${pattern.pattern}');
        } else {
          discountAmount = double.tryParse(value) ?? 0.0;
          discountType = 'fixed';
          debugPrint('Found fixed discount: \$$discountAmount using pattern: ${pattern.pattern}');
        }
        break;
      }
    }
    
    // Try to extract store name - enhanced patterns
    final storePatterns = [
      RegExp("at\\s+([A-Za-z0-9\\s&]+?)[\\.,\\s]?"),
      RegExp("from\\s+([A-Za-z0-9\\s&]+?)[\\.,\\s]?"),
      RegExp("([A-Za-z0-9\\s&]+?)\\s+voucher"),
      RegExp("([A-Za-z0-9\\s&]+?)\\s+coupon"),
      RegExp("([A-Za-z0-9\\s&]+?)\\s+offer"),
      // Look for store names in common positions
      RegExp("^([A-Za-z0-9\\s&]+?)[\\.,\\s]"),  // At the beginning
      // Look for store names that might be emphasized (all caps)
      RegExp("\\b([A-Z]{2,}[A-Z\\s&]+)\\b"),
      // Look for common store name patterns
      RegExp("shop\\s+(?:at|with)\\s+([A-Za-z0-9\\s&]+)"),
    ];
    
    for (final pattern in storePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        store = match.group(1)?.trim() ?? '';
        
        // Skip if the potential store name is too long
        if (store.length > 30) continue;
        
        // Capitalize first letter of each word
        store = store.split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
        ).join(' ');
        
        debugPrint('Found store: $store using pattern: ${pattern.pattern}');
        break;
      }
    }
    
    // If no store was found, try to use text that appears prominently
    if (store.isEmpty) {
      // Look at the first line, it might be the store name
      final lines = cleanedText.split('\n');
      if (lines.isNotEmpty && lines[0].length < 30) {
        store = lines[0].trim();
        debugPrint('Using first line as store: $store');
      }
    }
    
    // Try to extract expiry date - enhanced patterns
    final datePatterns = [
      // Standard date formats
      RegExp("expires?\\s+on\\s+(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"),
      RegExp("valid\\s+until\\s+(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"),
      RegExp("expires?\\s+(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"),
      // Word formats like "Jan 31, 2023"
      RegExp("expires?\\s+on\\s+([A-Za-z]{3,9}\\s+\\d{1,2},?\\s+\\d{4})"),
      RegExp("valid\\s+until\\s+([A-Za-z]{3,9}\\s+\\d{1,2},?\\s+\\d{4})"),
      RegExp("expires?\\s+([A-Za-z]{3,9}\\s+\\d{1,2},?\\s+\\d{4})"),
      // "Valid through" format
      RegExp("valid\\s+through\\s+(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"),
      RegExp("valid\\s+through\\s+([A-Za-z]{3,9}\\s+\\d{1,2},?\\s+\\d{4})"),
      // Expiration date without explicit mention
      RegExp("expiration\\s+date\\s*:?\\s*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"),
      RegExp("expiration\\s+date\\s*:?\\s*([A-Za-z]{3,9}\\s+\\d{1,2},?\\s+\\d{4})"),
      // End date
      RegExp("end\\s+date\\s*:?\\s*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"),
      RegExp("end\\s+date\\s*:?\\s*([A-Za-z]{3,9}\\s+\\d{1,2},?\\s+\\d{4})"),
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        final dateStr = match.group(1) ?? '';
        debugPrint('Found date string: $dateStr using pattern: ${pattern.pattern}');
        
        try {
          if (dateStr.contains('/') || dateStr.contains('-')) {
            // For formats like MM/DD/YYYY or DD/MM/YYYY
            final parts = dateStr.split(RegExp("[/-]"));
            if (parts.length == 3) {
              // Try both MM/DD/YYYY and DD/MM/YYYY interpretations
              try {
                // Assuming MM/DD/YYYY format
                int month = int.parse(parts[0]);
                int day = int.parse(parts[1]);
                int year = int.parse(parts[2]);
                
                // Adjust year if it's a 2-digit year
                if (year < 100) {
                  year += 2000;
                }
                
                final date = DateTime(year, month, day);
                // Is this date in the future or recent past?
                if (date.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
                  expiryDate = date;
                }
              } catch (_) {
                try {
                  // Try DD/MM/YYYY format
                  int day = int.parse(parts[0]);
                  int month = int.parse(parts[1]);
                  int year = int.parse(parts[2]);
                  
                  // Adjust year if it's a 2-digit year
                  if (year < 100) {
                    year += 2000;
                  }
                  
                  final date = DateTime(year, month, day);
                  // Is this date in the future or recent past?
                  if (date.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
                    expiryDate = date;
                  }
                } catch (_) {
                  // Both interpretations failed
                }
              }
            }
          } else {
            // For formats like "Jan 31, 2023" or "January 31, 2023"
            try {
              // Try "MMM d, yyyy" format
              expiryDate = DateFormat('MMM d, yyyy').parse(dateStr);
            } catch (_) {
              try {
                // Try "MMMM d, yyyy" format
                expiryDate = DateFormat('MMMM d, yyyy').parse(dateStr);
              } catch (_) {
                try {
                  // Try without comma "MMM d yyyy"
                  expiryDate = DateFormat('MMM d yyyy').parse(dateStr);
                } catch (_) {
                  // All formats failed
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing date: $e');
          // Continue to next pattern if this one fails
        }
        
        if (expiryDate != null) {
          debugPrint('Parsed expiry date: $expiryDate');
          break;
        }
      }
    }
    
    // If we couldn't extract an expiry date, set a default (30 days from now)
    expiryDate ??= DateTime.now().add(const Duration(days: 30));
    
    // Extract description - use first few words of the text if no better description found
    final lines = cleanedText.split('\n');
    if (lines.isNotEmpty) {
      // Use the first non-empty line as description if it's not too long
      for (final line in lines) {
        if (line.trim().isNotEmpty && line.length < 100) {
          description = line.trim();
          debugPrint('Using line for description: $description');
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
      debugPrint('Generated description: $description');
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
      debugPrint('Generated code: $code');
    }
    
    // Create a Voucher object with extracted details
    final extractedVoucher = Voucher(
      code: code,
      description: description,
      store: store,
      discountAmount: discountAmount,
      discountType: discountType,
      expiryDate: expiryDate,
      imageUrl: '',  // Will be set later when the image is saved
    );
    
    debugPrint('Extracted voucher details: $extractedVoucher');
    return VoucherExtractionResult(
      success: true,
      voucher: extractedVoucher,
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
