import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/voucher.dart';
import '../widgets/custom_app_bar.dart';
import '../services/notification_service.dart';
import '../providers/providers.dart';

class VoucherDetailsScreen extends StatefulWidget {
  final Voucher voucher;
  final Function onVoucherUpdated;
  
  const VoucherDetailsScreen({
    Key? key,
    required this.voucher,
    required this.onVoucherUpdated,
  }) : super(key: key);

  @override
  State<VoucherDetailsScreen> createState() => _VoucherDetailsScreenState();
}

class _VoucherDetailsScreenState extends State<VoucherDetailsScreen> {
  late Voucher _voucher;
  bool _isEditing = false;
  
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storeController = TextEditingController();
  final _discountAmountController = TextEditingController();
  
  String _discountType = 'percentage';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  int? _selectedCategoryId;
  bool _isUsed = false;
  
  @override
  void initState() {
    super.initState();
    _voucher = widget.voucher;
    _initFormValues();
  }
  
  void _initFormValues() {
    _codeController.text = _voucher.code;
    _descriptionController.text = _voucher.description;
    _storeController.text = _voucher.store;
    _discountAmountController.text = _voucher.discountAmount.toString();
    _discountType = _voucher.discountType;
    _expiryDate = _voucher.expiryDate;
    _selectedCategoryId = _voucher.categoryId;
    _isUsed = _voucher.isUsed;
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _storeController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }
  
  Future<void> _updateVoucher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final updatedVoucher = _voucher.copyWith(
      code: _codeController.text,
      description: _descriptionController.text,
      store: _storeController.text,
      discountAmount: double.tryParse(_discountAmountController.text) ?? 0.0,
      discountType: _discountType,
      expiryDate: _expiryDate,
      categoryId: _selectedCategoryId,
      isUsed: _isUsed,
    );
    
    final success = await Provider.of<VoucherProvider>(context, listen: false)
        .updateVoucher(updatedVoucher);
    
    if (success) {
      // Update the notification
      if (_voucher.isUsed != updatedVoucher.isUsed || 
          _voucher.expiryDate != updatedVoucher.expiryDate) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        
        // Cancel existing notification if any
        if (_voucher.id != null) {
          await notificationService.cancelNotification(_voucher.id!);
        }
        
        // Schedule new notification if not used and not expired
        if (!updatedVoucher.isUsed && !updatedVoucher.isExpired && updatedVoucher.id != null) {
          await notificationService.scheduleExpiryNotification(updatedVoucher);
        }
      }
      
      setState(() {
        _voucher = updatedVoucher;
        _isEditing = false;
      });
      
      widget.onVoucherUpdated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update voucher. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteVoucher() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voucher'),
        content: const Text('Are you sure you want to delete this voucher? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _voucher.id != null) {
      final success = await Provider.of<VoucherProvider>(context, listen: false)
          .deleteVoucher(_voucher.id!);
      
      if (success) {
        // Cancel notification
        if (_voucher.id != null) {
          await Provider.of<NotificationService>(context, listen: false)
              .cancelNotification(_voucher.id!);
        }
        
        widget.onVoucherUpdated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete voucher. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _toggleUsedStatus() async {
    final updatedVoucher = _voucher.copyWith(
      isUsed: !_voucher.isUsed,
    );
    
    final success = await Provider.of<VoucherProvider>(context, listen: false)
        .updateVoucher(updatedVoucher);
    
    if (success) {
      // Update notification status
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      if (updatedVoucher.isUsed && updatedVoucher.id != null) {
        // Cancel notification if voucher is marked as used
        await notificationService.cancelNotification(updatedVoucher.id!);
      } else if (!updatedVoucher.isUsed && !updatedVoucher.isExpired && updatedVoucher.id != null) {
        // Reschedule notification if voucher is marked as not used and not expired
        await notificationService.scheduleExpiryNotification(updatedVoucher);
      }
      
      setState(() {
        _voucher = updatedVoucher;
        _isUsed = updatedVoucher.isUsed;
      });
      
      widget.onVoucherUpdated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _voucher.isUsed
                ? 'Voucher marked as used!'
                : 'Voucher marked as active!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Voucher Details'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteVoucher,
            ),
          ],
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildVoucherDetails(),
    );
  }
  
  Widget _buildVoucherDetails() {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final category = categoryProvider.getCategoryById(_voucher.categoryId);
    
    final Color statusColor = _voucher.isExpired
        ? Colors.red
        : _voucher.isUsed
            ? Colors.grey
            : Colors.green;
    
    final String statusText = _voucher.isExpired
        ? 'Expired'
        : _voucher.isUsed
            ? 'Used'
            : 'Active';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Voucher image
          if (_voucher.imageUrl.isNotEmpty) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(_voucher.imageUrl),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text('Failed to load image'),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Voucher code section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VOUCHER CODE',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy code',
                      onPressed: () => _copyToClipboard(_voucher.code),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _voucher.code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Voucher details
          _buildDetailRow('Store/Brand', _voucher.store),
          _buildDetailRow('Description', _voucher.description),
          _buildDetailRow(
            'Discount',
            _voucher.discountType == 'percentage'
                ? '${_voucher.discountAmount.toStringAsFixed(0)}%'
                : '\$${_voucher.discountAmount.toStringAsFixed(2)}',
          ),
          _buildDetailRow('Category', category?.name ?? 'None'),
          _buildDetailRow('Expires On', _voucher.formattedExpiryDate),
          _buildDetailRow('Days Left', _voucher.isExpired
              ? 'Expired'
              : '${_voucher.daysUntilExpiry} days'),
          _buildDetailRow('Added On', _voucher.formattedCreatedDate),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleUsedStatus,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: Text(_voucher.isUsed ? 'Mark as Unused' : 'Mark as Used'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
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
  
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voucher code
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Voucher Code *',
                hintText: 'Enter the voucher code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voucher code is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Enter a description for the voucher',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Store/Brand
            TextFormField(
              controller: _storeController,
              decoration: const InputDecoration(
                labelText: 'Store/Brand *',
                hintText: 'Enter the store or brand name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Store/Brand is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Discount information
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
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
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
            
            // Expiry date
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
                    text: DateFormat('MM/dd/yyyy').format(_expiryDate),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Expiry date is required';
                    }
                    return null;
                  },
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
            
            const SizedBox(height: 16),
            
            // Used status
            SwitchListTile(
              title: const Text('Mark as Used'),
              subtitle: const Text('Toggle if you have already used this voucher'),
              value: _isUsed,
              onChanged: (value) {
                setState(() {
                  _isUsed = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _initFormValues(); // Reset form values
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateVoucher,
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
