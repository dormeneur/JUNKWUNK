/// AWS Cognito Configuration
///
/// This file contains the configuration for AWS Cognito User Pool
/// Replace these values if you recreate the user pool

class AWSConfig {
  // Cognito User Pool Configuration
  static const String userPoolId = 'ap-south-1_KEGPzHo0I';
  static const String clientId = 'os5urmu6qi4k96ascqt5m2re0';
  static const String region = 'ap-south-1';

  // Identity Pool (not needed for basic auth, but kept for future use)
  static const String identityPoolId = ''; // Not created yet

  // App Configuration
  static const String appName = 'JunkWunk';
}
