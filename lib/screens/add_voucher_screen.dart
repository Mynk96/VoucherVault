import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/voucher.dart';
import '../models/category.dart';
import '../providers/providers.dart';
import '../services/ocr_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';
import 'ocr_process_screen.dart';

class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({Key? key}) : super(key: key);

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storeController = TextEditingController();
  final _discountAmountController = TextEditingController();
  
  String _discountType = 'percentage';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  int? _selectedCategoryId;
  File? _imageFile;
  bool _isProcessing = false;
  
  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _storeController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        if (source == ImageSource.camera) {
          // If it's a camera image, process with OCR directly
          final File imageFile = File(pickedFile.path);
          _processWithOCR(imageFile);
        } else {
          // For gallery images, just set the image file
          setState(() {
            _imageFile = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _processWithOCR(File imageFile) async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Navigate to processing screen
      final result = await Navigator.push<Voucher>(
        context,
        MaterialPageRoute(
          builder: (context) => OcrProcessScreen(imageFile: imageFile),
        ),
      );
      
      if (result != null) {
        // Populate form with extracted data
        setState(() {
          _codeController.text = result.code;
          _descriptionController.text = result.description;
          _storeController.text = result.store;
          _discountAmountController.text = result.discountAmount.toString();
          _discountType = result.discountType;
          _expiryDate = result.expiryDate;
          _selectedCategoryId = result.categoryId;
          _imageFile = imageFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<String> _saveImage(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'voucher_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: ${e.toString()}');
      return '';
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }
  
  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _saveImage(_imageFile!);
      }
      
      final voucher = Voucher(
        code: _codeController.text,
        description: _descriptionController.text,
        store: _storeController.text,
        discountAmount: double.tryParse(_discountAmountController.text) ?? 0.0,
        discountType: _discountType,
        expiryDate: _expiryDate,
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl,
      );
      
      final success = await Provider.of<VoucherProvider>(context, listen: false)
          .addVoucher(voucher);
      
      if (success && voucher.id != null) {
        // Schedule notification for this voucher
        await Provider.of<NotificationService>(context, listen: false)
            .scheduleExpiryNotification(voucher);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save voucher. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Voucher'),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker section
                    Center(
                      child: Column(
                        children: [
                          if (_imageFile != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                _imageFile!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                });
                              },
                              child: const Text('Remove Image'),
                            ),
                          ] else ...[
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No Image Selected'),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _pickImage(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt),
                                        label: const Text('Camera'),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => _pickImage(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library),
                                        label: const Text('Gallery'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Form fields
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Voucher Code *',
                        hintText: 'Enter the voucher code',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => Validators.validateRequired(
                        value,
                        'Voucher code is required',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Enter a description for the voucher',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => Validators.validateRequired(
                        value,
                        'Description is required',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _storeController,
                      decoration: const InputDecoration(
                        labelText: 'Store/Brand *',
                        hintText: 'Enter the store or brand name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => Validators.validateRequired(
                        value,
                        'Store/Brand is required',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _discountAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Discount Amount',
                              hintText: 'e.g., 20',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => Validators.validateNumber(
                              value,
                              'Please enter a valid number',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _discountType,
                            decoration: const InputDecoration(
                              labelText: 'Discount Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Percentage (%)'),
                              ),
                              DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Fixed Amount (\$)'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _discountType = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Expiry date picker
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Expiry Date *',
                            hintText: 'Select expiry date',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          controller: TextEditingController(
                            text: '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
                          ),
                          validator: (value) => Validators.validateRequired(
                            value,
                            'Expiry date is required',
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        return DropdownButtonFormField<int?>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'Select a category',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('No Category'),
                            ),
                            ...categoryProvider.categories.map((category) {
                              return DropdownMenuItem<int?>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveVoucher,
                        child: const Text('Save Voucher'),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
