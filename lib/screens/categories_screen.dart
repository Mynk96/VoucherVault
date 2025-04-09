import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/providers.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#4CAF50'; // Default green color
  int _selectedIconCodePoint = 0xe59c; // Default shopping_bag icon
  
  bool _isEditing = false;
  Category? _editingCategory;
  
  final List<Color> _colorOptions = [
    const Color(0xFFF44336), // Red
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Blue
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFF4CAF50), // Green
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFCDDC39), // Lime
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF795548), // Brown
    const Color(0xFF9E9E9E), // Grey
    const Color(0xFF607D8B), // Blue Grey
  ];
  
  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'Food & Drink', 'codePoint': 0xe25a}, // restaurant
    {'name': 'Shopping', 'codePoint': 0xe59c}, // shopping_bag
    {'name': 'Travel', 'codePoint': 0xe570}, // flight
    {'name': 'Entertainment', 'codePoint': 0xe40f}, // movie
    {'name': 'Health', 'codePoint': 0xe3f3}, // medical_services
    {'name': 'Fashion', 'codePoint': 0xea48}, // checkroom
    {'name': 'Tech', 'codePoint': 0xe31e}, // devices
    {'name': 'Beauty', 'codePoint': 0xeb81}, // spa
    {'name': 'Sports', 'codePoint': 0xea64}, // sports_basketball
    {'name': 'Home', 'codePoint': 0xe22a}, // home
    {'name': 'Education', 'codePoint': 0xe80c}, // school
    {'name': 'Transport', 'codePoint': 0xe531}, // directions_car
    {'name': 'Gifts', 'codePoint': 0xe8f6}, // card_giftcard
    {'name': 'Other', 'codePoint': 0xe3e3}, // more_horiz
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  void _resetForm() {
    _nameController.clear();
    _selectedColor = '#4CAF50';
    _selectedIconCodePoint = 0xe59c;
    _isEditing = false;
    _editingCategory = null;
  }
  
  void _editCategory(Category category) {
    setState(() {
      _isEditing = true;
      _editingCategory = category;
      _nameController.text = category.name;
      _selectedColor = category.color;
      _selectedIconCodePoint = category.iconCodePoint;
    });
  }
  
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    final category = _isEditing
        ? _editingCategory!.copyWith(
            name: _nameController.text,
            color: _selectedColor,
            iconCodePoint: _selectedIconCodePoint,
          )
        : Category(
            name: _nameController.text,
            color: _selectedColor,
            iconCodePoint: _selectedIconCodePoint,
          );
    
    bool success;
    if (_isEditing) {
      success = await categoryProvider.updateCategory(category);
    } else {
      success = await categoryProvider.addCategory(category);
    }
    
    if (success) {
      _resetForm();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Category updated successfully!'
              : 'Category added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save category. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteCategory(Category category) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'Vouchers in this category will be moved to "No Category".',
        ),
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
    
    if (confirmed == true && category.id != null) {
      final success = await Provider.of<CategoryProvider>(context, listen: false)
          .deleteCategory(category.id!);
      
      if (success) {
        if (_isEditing && _editingCategory?.id == category.id) {
          _resetForm();
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete category. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancel Editing',
              onPressed: _resetForm,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryForm(),
          const Divider(height: 32),
          Expanded(
            child: _buildCategoryList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Category' : 'Add New Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter a name for this category',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Select Color'),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _colorOptions.map((color) {
                  final hexColor = '#${color.value.toRadixString(16).substring(2)}';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = hexColor;
                        });
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: color,
                        child: _selectedColor == hexColor
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Icon'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _iconOptions.length,
                itemBuilder: (context, index) {
                  final icon = _iconOptions[index];
                  final codePoint = icon['codePoint'] as int;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIconCodePoint = codePoint;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIconCodePoint == codePoint
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedIconCodePoint == codePoint
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Icon(
                        IconData(codePoint, fontFamily: 'MaterialIcons'),
                        color: _selectedIconCodePoint == codePoint
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveCategory,
                child: Text(_isEditing ? 'Update Category' : 'Add Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryList() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (provider.error.isNotEmpty) {
          return Center(
            child: Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        
        if (provider.categories.isEmpty) {
          return const Center(
            child: Text('No categories found. Add one to get started!'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.categories.length,
          itemBuilder: (context, index) {
            final category = provider.categories[index];
            
            // Parse the hex color
            final hexColor = category.color;
            final color = Color(int.parse('0xFF${hexColor.substring(1)}'));
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: Icon(
                    IconData(category.iconCodePoint, fontFamily: category.iconFontFamily),
                    color: Colors.white,
                  ),
                ),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editCategory(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCategory(category),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
