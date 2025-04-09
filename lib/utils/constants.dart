class AppConstants {
  // App Details
  static const String appName = 'VoucherKeeper';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Manage all your vouchers in one place';
  
  // Database
  static const String databaseName = 'voucher_manager.db';
  static const int databaseVersion = 1;
  
  // Notification Channels
  static const String expiryNotificationChannelId = 'voucher_expiry_channel';
  static const String expiryNotificationChannelName = 'Voucher Expiry Notifications';
  static const String expiryNotificationChannelDescription = 'Notifications for vouchers about to expire';
  
  static const String immediateNotificationChannelId = 'voucher_immediate_channel';
  static const String immediateNotificationChannelName = 'Immediate Notifications';
  static const String immediateNotificationChannelDescription = 'Notifications that show immediately';
  
  // Default Settings
  static const bool defaultNotificationsEnabled = true;
  static const int defaultExpiryThreshold = 7; // days
  
  // Shared Preferences Keys
  static const String prefsNotificationsEnabled = 'notifications_enabled';
  static const String prefsExpiryThreshold = 'expiry_threshold';
  static const String prefsIsFirstTime = 'is_first_time';
  
  // Discount Types
  static const List<String> discountTypes = [
    'percentage',
    'fixed',
    'other',
  ];
  
  // Validation
  static const int maxCodeLength = 50;
  static const int maxDescriptionLength = 200;
  static const int maxStoreLength = 100;
  
  // Export/Import
  static const String exportFilePrefix = 'voucher_export_';
  static const String exportFileExtension = '.json';
  
  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double chipBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorLoadingVouchers = 'Failed to load vouchers. Please try again.';
  static const String errorSavingVoucher = 'Failed to save voucher. Please try again.';
  static const String errorUpdatingVoucher = 'Failed to update voucher. Please try again.';
  static const String errorDeletingVoucher = 'Failed to delete voucher. Please try again.';
  
  static const String errorLoadingCategories = 'Failed to load categories. Please try again.';
  static const String errorSavingCategory = 'Failed to save category. Please try again.';
  static const String errorUpdatingCategory = 'Failed to update category. Please try again.';
  static const String errorDeletingCategory = 'Failed to delete category. Please try again.';
  
  static const String errorProcessingImage = 'Failed to process image. Please try again.';
  static const String errorSchedulingNotification = 'Failed to schedule notification. Please check app permissions.';
}
