---
name: strata-bootstrap
description: Set up and bootstrap the Strata framework in a Flutter project, including StrataInitializer, StrataConfigEntity, dependency injection with GetIt, and network configuration.
---

# Strata Bootstrap Skill

Bootstrap and configure the Strata framework in a Flutter application.

---

## 🛠️ Step-by-Step Workflow

### Step 1: Verify & Add Dependencies
Inspect the host application's `pubspec.yaml`:
1. Check if `strata` is in `dependencies:`.
2. If missing, add it via:
   ```bash
   flutter pub add strata
   ```
   *(Or specify the monorepo path if developing locally).*
3. Ensure `get_it` is available (exported by `strata`, but can be explicitly declared).
4. Run `flutter pub get`.

---

### Step 2: Configure `StrataConfigEntity`
Create or update your app configuration file (e.g., `lib/core/config/app_strata_config.dart` or directly in `main.dart`):

```dart
import 'package:strata/strata.dart';

StrataConfigEntity createStrataConfig({
  required String baseUrl,
  bool isDebug = true,
}) {
  return StrataConfigEntity(
    networkConfig: NetworkConfigEntity(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      accessTokenKey: 'access_token',
      refreshTokenKey: 'refresh_token',
      refreshTokenApiEndpoint: '/auth/refresh',
      excludedPaths: const ['/auth/login', '/auth/register', '/auth/refresh'],
      enableRetry: true,
      maxRetryAttempts: 3,
      retryInterval: const Duration(seconds: 2),
    ),
    logger: isDebug ? null : null, // Uses default Strata talker logger if null
  );
}
```

---

### Step 3: Wire `main.dart`
Update `main.dart` to initialize Flutter bindings and run `StrataInitializer.initialize(...)` prior to `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:strata/strata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final strataConfig = StrataConfigEntity(
    networkConfig: const NetworkConfigEntity(
      baseUrl: 'https://api.example.com',
      accessTokenKey: 'access_token',
      refreshTokenKey: 'refresh_token',
      refreshTokenApiEndpoint: '/auth/refresh',
      excludedPaths: ['/auth/login', '/auth/register'],
      enableRetry: true,
    ),
  );

  // Initializes strata_core, strata_storage, strata_network, strata_state, strata_ui
  await StrataInitializer.initialize(strataConfig);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Strata Application',
      home: Scaffold(
        body: Center(
          child: Text('Strata Initialized Successfully'),
        ),
      ),
    );
  }
}
```

---

### Step 4: Verification
Execute static analysis to ensure all imports and configurations compile cleanly:
```bash
flutter analyze
```

**Completion Criteria**: `flutter analyze` completes with zero errors, and `StrataInitializer.initialize` is awaited before `runApp`.

---

### Step 5: Auth Handoff Prompt
Once bootstrap completes successfully, ask the developer:
> *"Strata initialization is complete! Would you like to set up the authentication and token lifecycle now using `@strata-auth`?"*
