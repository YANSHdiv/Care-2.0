/// Care 2.0 — App Constants
library;

class AppConstants {
  AppConstants._();
  
  static const String appName = 'Care 2.0';
  static const String appTagline = 'Preventive Health, Redefined.';
  static const String appVersion = '1.0.0';
  
  // Default user ID for prototype
  static const String defaultUid = 'demo_user_001';
  
  // Delhi coordinates (default)
  static const double defaultLat = 28.6139;
  static const double defaultLon = 77.2090;
  
  // Blood groups
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  // Hereditary diseases
  static const List<String> hereditaryDiseases = [
    'Diabetes',
    'Hypertension',
    'Heart Disease',
    'Cancer',
    'Alzheimer\'s',
    'Asthma',
    'Thyroid Disorder',
    'Kidney Disease',
    'Obesity',
    'Arthritis',
  ];
  
  // Medical conditions
  static const List<String> medicalConditions = [
    'Hypertension',
    'Diabetes',
    'Asthma',
    'Heart Disease',
    'Thyroid Disorder',
    'Anemia',
    'Obesity',
    'COPD',
    'Kidney Disease',
    'High Cholesterol',
    'Anxiety',
    'Depression',
  ];
  
  // Family relatives
  static const List<String> relatives = [
    'Father',
    'Mother',
    'Paternal Grandfather',
    'Paternal Grandmother',
    'Maternal Grandfather',
    'Maternal Grandmother',
  ];
}
