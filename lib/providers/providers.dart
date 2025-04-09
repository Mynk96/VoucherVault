import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class VoucherProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String _error = '';
  
  VoucherProvider(this._databaseService) {
    loadVouchers();
  }
  
  List<Voucher> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  Future<void> loadVouchers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _vouchers = await _databaseService.getVouchers();
      _error = '';
    } catch (e) {
      _error = 'Failed to load vouchers: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> addVoucher(Voucher voucher) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final id = await _databaseService.insertVoucher(voucher);
      if (id > 0) {
        voucher.id = id;
        _vouchers.add(voucher);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to add voucher: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateVoucher(Voucher voucher) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _databaseService.updateVoucher(voucher);
      if (success) {
        final index = _vouchers.indexWhere((v) => v.id == voucher.id);
        if (index != -1) {
          _vouchers[index] = voucher;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update voucher: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteVoucher(int id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _databaseService.deleteVoucher(id);
      if (success) {
        _vouchers.removeWhere((v) => v.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete voucher: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  List<Voucher> searchVouchers(String query, {int? categoryId, bool? onlyFavorites, bool? onlyActive}) {
    if (query.isEmpty && categoryId == null && onlyFavorites != true && onlyActive != true) {
      return _vouchers;
    }
    
    return _vouchers.where((voucher) {
      final matchesQuery = query.isEmpty || 
        voucher.code.toLowerCase().contains(query.toLowerCase()) ||
        voucher.description.toLowerCase().contains(query.toLowerCase()) ||
        voucher.store.toLowerCase().contains(query.toLowerCase()) ||
        voucher.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        
      final matchesCategory = categoryId == null || voucher.categoryId == categoryId;
      
      final matchesFavorite = onlyFavorites != true || voucher.isFavorite;
      
      final matchesActive = onlyActive != true || (!voucher.isExpired && !voucher.isUsed);
      
      return matchesQuery && matchesCategory && matchesFavorite && matchesActive;
    }).toList();
  }
  
  List<Voucher> getExpiringVouchers() {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    
    return _vouchers.where((voucher) {
      return !voucher.isUsed && 
             !voucher.isExpired && 
             voucher.expiryDate.isBefore(sevenDaysLater);
    }).toList();
  }
  
  // New methods for additional features
  List<Voucher> getFavoriteVouchers() {
    return _vouchers.where((voucher) => voucher.isFavorite).toList();
  }
  
  List<Voucher> getVouchersByTag(String tag) {
    return _vouchers.where(
      (voucher) => voucher.tags.any(
        (t) => t.toLowerCase() == tag.toLowerCase()
      )
    ).toList();
  }
  
  Future<List<String>> getAllTags() async {
    final Set<String> allTags = {};
    
    for (final voucher in _vouchers) {
      allTags.addAll(voucher.tags);
    }
    
    return allTags.toList()..sort();
  }
  
  Future<bool> toggleVoucherFavorite(int id) async {
    try {
      final success = await _databaseService.toggleVoucherFavorite(id);
      if (success) {
        await loadVouchers(); // Reload to get updated voucher
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to toggle favorite: ${e.toString()}';
      return false;
    }
  }
  
  Future<bool> markVoucherAsUsed(int id, {String? notes}) async {
    try {
      final success = await _databaseService.markVoucherAsUsed(id, notes: notes);
      if (success) {
        await loadVouchers(); // Reload to get updated voucher
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to mark voucher as used: ${e.toString()}';
      return false;
    }
  }
  
  Future<Map<String, dynamic>> getVoucherUsageHistory(int id) async {
    try {
      return {
        'success': true,
        'history': await _databaseService.getVoucherUsageHistory(id),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  Future<Map<String, dynamic>> getVoucherStatistics() async {
    try {
      return {
        'success': true,
        'stats': await _databaseService.getVoucherStatistics(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<Category> _categories = [];
  bool _isLoading = false;
  String _error = '';
  
  CategoryProvider(this._databaseService) {
    loadCategories();
  }
  
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _categories = await _databaseService.getCategories();
      _error = '';
    } catch (e) {
      _error = 'Failed to load categories: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Category? getCategoryById(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere(
        (category) => category.id == id,
      );
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> addCategory(Category category) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final id = await _databaseService.insertCategory(category);
      if (id > 0) {
        category.id = id;
        _categories.add(category);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to add category: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateCategory(Category category) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _databaseService.updateCategory(category);
      if (success) {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = category;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update category: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _databaseService.deleteCategory(id);
      if (success) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete category: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}