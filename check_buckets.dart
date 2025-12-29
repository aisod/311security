// Dart script to check if Supabase storage buckets exist
// Run this with: dart run check_buckets.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('============================================');
  print('CHECKING SUPABASE STORAGE BUCKETS');
  print('============================================\n');

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    final supabase = Supabase.instance.client;

    print('✅ Connected to Supabase\n');

    // Required buckets
    final requiredBuckets = [
      'avatars',
      'crime-evidence',
      'notification-images',
    ];

    print('Checking for required buckets...\n');

    int existingCount = 0;
    int missingCount = 0;

    for (final bucketName in requiredBuckets) {
      try {
        // Try to list files in the bucket (this will fail if bucket doesn't exist)
        final response = await supabase.storage.from(bucketName).list();
        
        print('✅ $bucketName - EXISTS');
        print('   Files: ${response.length}');
        existingCount++;
      } catch (e) {
        print('❌ $bucketName - MISSING');
        print('   Error: ${e.toString()}');
        missingCount++;
      }
      print('');
    }

    // Summary
    print('============================================');
    print('SUMMARY');
    print('============================================');
    print('Total required: ${requiredBuckets.length}');
    print('Existing: $existingCount');
    print('Missing: $missingCount');
    print('');

    if (missingCount == 0) {
      print('✅ ALL BUCKETS CONFIGURED!');
      print('');
      print('Your storage is ready to use! 🎉');
    } else {
      print('⚠️ SOME BUCKETS ARE MISSING');
      print('');
      print('Next steps:');
      print('1. Go to https://supabase.com/dashboard');
      print('2. Select your project');
      print('3. Go to Storage');
      print('4. Create the missing buckets');
      print('');
      print('Or run the SQL script:');
      print('   supabase/migrations/create_storage_buckets.sql');
    }
    print('============================================\n');

    exit(0);
  } catch (e) {
    print('❌ ERROR: $e\n');
    print('Make sure your .env file is configured with:');
    print('  - SUPABASE_URL');
    print('  - SUPABASE_ANON_KEY');
    exit(1);
  }
}

