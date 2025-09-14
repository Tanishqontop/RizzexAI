# Phone OTP Verification Implementation Guide

## Overview

This guide explains how to implement real phone OTP (One-Time Password) verification in your RizzexAI Flutter app using Supabase Auth. The implementation replaces the mock verification with actual SMS-based OTP verification.

## What Was Implemented

### 1. Enhanced AuthService (`lib/services/auth_service.dart`)

Added three new methods for phone authentication:

#### `signInWithPhone(String phoneNumber)`
- Sends OTP to the provided phone number
- Uses Supabase's `signInWithOtp()` method
- Handles errors and provides detailed logging

#### `verifyPhoneOtp({required String phone, required String token})`
- Verifies the OTP entered by the user
- Creates user profile if it doesn't exist
- Returns authenticated user session

#### `resendPhoneOtp(String phoneNumber)`
- Resends OTP to the same phone number
- Uses Supabase's `resend()` method with SMS type

### 2. Updated Phone Verification Screen (`lib/screens/phone_verification_screen.dart`)

Enhanced with:
- Loading states during OTP sending
- Real OTP sending using AuthService
- Error handling with user-friendly messages
- Proper phone number formatting (country code + number)

### 3. Updated OTP Verification Screen (`lib/screens/otp_verification_screen.dart`)

Enhanced with:
- Real OTP verification using AuthService
- Loading states during verification
- Resend OTP functionality
- Automatic OTP field clearing on error
- Better error messages and user feedback

## Setup Requirements

### 1. Supabase Configuration

You need to configure phone authentication in your Supabase project:

1. **Enable Phone Auth in Supabase Dashboard:**
   - Go to Authentication > Settings
   - Enable "Enable phone confirmations"
   - Configure your SMS provider (Twilio, MessageBird, etc.)

2. **Set up SMS Provider:**
   ```bash
   # Example for Twilio (in Supabase Dashboard)
   TWILIO_ACCOUNT_SID=your_account_sid
   TWILIO_AUTH_TOKEN=your_auth_token
   TWILIO_PHONE_NUMBER=your_twilio_phone_number
   ```

### 2. Database Schema

Ensure your `profiles` table exists:
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. Flutter Dependencies

Your `pubspec.yaml` already includes the required dependencies:
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  shared_preferences: ^2.2.2
```

## Usage Flow

### 1. User enters phone number
- Phone number is validated (minimum 10 digits)
- Country code is selected from the picker
- Full number format: `+91XXXXXXXXXX`

### 2. Send OTP
```dart
await AuthService.signInWithPhone(fullPhoneNumber);
```

### 3. User enters OTP
- 6-digit OTP input with automatic focus management
- Real-time validation of OTP completion

### 4. Verify OTP
```dart
final response = await AuthService.verifyPhoneOtp(
  phone: phoneNumber,
  token: otp,
);
```

### 5. Success handling
- User profile creation (if new user)
- Navigation to onboarding screens
- Local storage of verification status

## Error Handling

The implementation includes comprehensive error handling:

- **Network errors**: Connection issues, timeouts
- **Invalid phone numbers**: Format validation
- **Invalid OTP**: Wrong code entered
- **Rate limiting**: Too many requests
- **Service unavailable**: Supabase/SMS provider issues

## Security Features

1. **Rate Limiting**: Supabase automatically rate limits OTP requests
2. **OTP Expiration**: OTPs expire after a set time (configurable in Supabase)
3. **Secure Storage**: User sessions stored securely by Supabase
4. **Phone Validation**: Client-side and server-side validation

## Testing

### Development Testing
For development, you can:
1. Use test phone numbers provided by your SMS provider
2. Check Supabase logs for OTP codes during development
3. Use Supabase's test mode if available

### Production Considerations
1. **SMS Costs**: Each OTP sends a billable SMS
2. **Rate Limiting**: Implement additional client-side rate limiting if needed
3. **Error Monitoring**: Monitor authentication errors in production
4. **User Experience**: Consider adding countdown timers for resend functionality

## Customization Options

### 1. OTP Length
Currently set to 6 digits. To change:
```dart
// In OtpVerificationScreen
final List<TextEditingController> _otpControllers = List.generate(
  4, // Change from 6 to 4 for 4-digit OTP
  (index) => TextEditingController(),
);
```

### 2. Country Codes
Add more countries in `PhoneVerificationScreen`:
```dart
List<Map<String, String>> _getCountries() {
  return [
    {'name': 'Your Country', 'code': '+XX', 'flag': '🏳️'},
    // ... existing countries
  ];
}
```

### 3. Error Messages
Customize error messages in the catch blocks of each method.

### 4. UI Styling
All UI elements use your existing design system with Google Fonts and consistent colors.

## Troubleshooting

### Common Issues

1. **OTP not received**
   - Check SMS provider configuration
   - Verify phone number format
   - Check Supabase logs

2. **"Invalid OTP" error**
   - Ensure OTP hasn't expired
   - Check for typos in phone number
   - Verify SMS provider is working

3. **Profile creation fails**
   - Check database permissions
   - Ensure profiles table exists
   - Verify RLS policies

### Debug Logging

The implementation includes detailed logging. Check your Flutter console for:
```
AuthService: Sending OTP to phone: +1234567890
AuthService: OTP sent successfully
AuthService: Verifying OTP for phone: +1234567890
AuthService: User ID: user_id_here
```

## Next Steps

1. **Add countdown timer** for resend button
2. **Implement biometric authentication** for returning users
3. **Add phone number change** functionality in user settings
4. **Set up analytics** to track authentication success rates
5. **Add automated testing** for the authentication flow

## Support

For issues related to:
- **Supabase Auth**: Check Supabase documentation and community
- **SMS Provider**: Contact your SMS provider support
- **Flutter Implementation**: Review the code comments and error logs

---

**Note**: Remember to test thoroughly in a development environment before deploying to production, as SMS costs apply for each OTP sent.
