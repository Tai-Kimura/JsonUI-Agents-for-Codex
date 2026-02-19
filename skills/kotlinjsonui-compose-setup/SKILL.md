---
name: kotlinjsonui-compose-setup
description: Setup and development workflow for KotlinJsonUI with Jetpack Compose mode.
---

# KotlinJsonUI Setup (Compose Mode)

## CRITICAL - Package Name

```
Gradle artifact:  io.github.tai-kimura:kotlinjsonui
Kotlin import:    com.kotlinjsonui.core
```

**CORRECT imports:**
```kotlin
import com.kotlinjsonui.core.DynamicModeManager
import com.kotlinjsonui.core.Configuration
```

---

## Checklist

- [ ] Step 1: Project root confirmed (build.gradle.kts exists)
- [ ] Step 2: KotlinJsonUI version requirements checked
- [ ] Step 3: Dependencies added to app/build.gradle.kts
- [ ] Step 4: kjui_tools installed
- [ ] Step 5: kjui.config.json created
- [ ] Step 6: Port configured (8082)
- [ ] Step 7: setup command executed
- [ ] Step 8: Application class created
- [ ] Step 9: AndroidManifest.xml modified
- [ ] Step 10: MainActivity.kt modified
- [ ] Step 11: Splash view generated
- [ ] Step 12: Final verification passed

---

## Step 1: Go to project root
```bash
cd <project_directory>  # Provided by setup agent (NOT app/ folder)
ls build.gradle.kts settings.gradle.kts  # VERIFY: Both files must exist
```

## Step 2: Check KotlinJsonUI version requirements
```bash
curl -sSL https://raw.githubusercontent.com/Tai-Kimura/KotlinJsonUI/main/gradle/libs.versions.toml 2>/dev/null | grep -E "^kotlin|^composeBom"
```

## Step 3: Add dependencies to app/build.gradle.kts

```kotlin
android {
    buildFeatures { compose = true }
    composeOptions { kotlinCompilerExtensionVersion = "1.5.7" }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.runtime:runtime")
    implementation("androidx.activity:activity-compose:1.8.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")

    implementation("io.github.tai-kimura:kotlinjsonui:1.0.2")
    debugImplementation("io.github.tai-kimura:kotlinjsonui-dynamic:1.0.2")

    implementation("com.google.code.gson:gson:2.10.1")
    implementation("io.coil-kt:coil-compose:2.5.0")
    implementation("androidx.constraintlayout:constraintlayout-compose:1.1.0")
}
```

## Step 4: Copy kjui_tools to project
```bash
cp -r <jsonui_cli_path>/kjui_tools ./
ls kjui_tools/bin/kjui  # VERIFY: File must exist
```

## Step 5: Initialize
```bash
./kjui_tools/bin/kjui init --mode compose
ls kjui.config.json  # VERIFY: File must exist
```

## Step 6: Verify and Edit kjui.config.json

**Required checks:**
1. `source_directory` - e.g., `app/src/main`
2. `layouts_directory` - e.g., `assets/Layouts`
3. `view_directory` - e.g., `kotlin/com/yourpackage/views`
4. `package_name` - Must match your actual package name
5. `hotloader.port` - Set to `8082`

## Step 7: Run setup
```bash
./kjui_tools/bin/kjui setup
```

## Step 8: Create Application class

Create `app/src/main/kotlin/<package>/YourAppApplication.kt`:
```kotlin
package com.yourpackage

import android.app.Application
import com.kotlinjsonui.core.KotlinJsonUI

class YourAppApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        KotlinJsonUI.initialize(this)
    }
}
```

## Step 9: Edit AndroidManifest.xml

Add `android:name` to `<application>`:
```xml
<application
    android:name=".YourAppApplication"
    ...>
```

## Step 10: Edit MainActivity.kt

```kotlin
package com.yourpackage

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import com.kotlinjsonui.core.DeveloperMenuContainer
import com.kotlinjsonui.core.DeveloperScreen
import com.kotlinjsonui.core.DynamicModeManager
import com.yourpackage.views.splash.SplashView
import com.yourpackage.ui.theme.YourAppTheme

enum class Screen : DeveloperScreen {
    Splash;
    override val displayName: String get() = this.name
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        DynamicModeManager.setDynamicModeEnabled(this, false)

        setContent {
            var currentScreen by remember { mutableStateOf(Screen.Splash) }
            val developerMenuEnabled = true

            YourAppTheme {
                DeveloperMenuContainer(
                    currentScreen = currentScreen,
                    screens = Screen.entries,
                    onScreenChange = { currentScreen = it },
                    enabled = developerMenuEnabled
                ) { screen ->
                    when (screen) {
                        Screen.Splash -> SplashView()
                    }
                }
            }
        }
    }
}
```

## Step 11: Generate Splash view
```bash
./kjui_tools/bin/kjui g view Splash --root
```

## Step 12: Final Verification

Verify these files exist:
1. `kjui_tools/bin/kjui`
2. `kjui.config.json`
3. Application class with `KotlinJsonUI.initialize(this)`
4. MainActivity.kt with `DeveloperMenuContainer`
5. `{layout_path}/splash/` directory

## Hotloader Commands
```bash
./kjui_tools/bin/kjui hotload listen
adb forward tcp:8082 tcp:8082
```

