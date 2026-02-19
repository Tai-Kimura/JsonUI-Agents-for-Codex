---
name: kotlinjsonui-xml-setup
description: Setup and development workflow for KotlinJsonUI with Android Views (XML) mode.
---

# KotlinJsonUI Setup (XML Mode)

## CRITICAL - Package Name

```
Gradle artifact:  io.github.tai-kimura:kotlinjsonui
Kotlin import:    com.kotlinjsonui.core
```

---

## Checklist

- [ ] Step 1: Project root confirmed (build.gradle.kts exists)
- [ ] Step 2: KotlinJsonUI version requirements checked
- [ ] Step 3: Dependencies added to app/build.gradle.kts
- [ ] Step 4: kjui_tools installed
- [ ] Step 5: kjui.config.json created (mode: xml)
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
cd <project_directory>  # Provided by setup agent
ls build.gradle.kts settings.gradle.kts  # VERIFY: Both files must exist
```

## Step 2: Check KotlinJsonUI version requirements
```bash
curl -sSL https://raw.githubusercontent.com/Tai-Kimura/KotlinJsonUI/main/gradle/libs.versions.toml 2>/dev/null | grep -E "^kotlin"
```

## Step 3: Add dependencies to app/build.gradle.kts

```kotlin
dependencies {
    implementation("io.github.tai-kimura:kotlinjsonui:1.0.2")
    debugImplementation("io.github.tai-kimura:kotlinjsonui-dynamic:1.0.2")
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("io.coil-kt:coil:2.5.0")
}
```

## Step 4: Copy kjui_tools to project
```bash
cp -r <jsonui_cli_path>/kjui_tools ./
ls kjui_tools/bin/kjui  # VERIFY: File must exist
```

## Step 5: Initialize (XML mode)
```bash
./kjui_tools/bin/kjui init --mode xml
ls kjui.config.json  # VERIFY
```

## Step 6: Verify and Edit kjui.config.json

Set `hotloader.port` to `8082`

## Step 7: Run setup
```bash
./kjui_tools/bin/kjui setup
```

## Step 8: Create Application class

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

Add `android:name=".YourAppApplication"` to `<application>`

## Step 10: Edit MainActivity.kt

Setup for XML-based views with Fragment/Activity navigation.

## Step 11: Generate Splash view
```bash
./kjui_tools/bin/kjui g view Splash --root
```

## Step 12: Final Verification

Verify all files exist and Application class contains `KotlinJsonUI.initialize(this)`

## Hotloader Commands
```bash
./kjui_tools/bin/kjui hotload listen
adb forward tcp:8082 tcp:8082
```

