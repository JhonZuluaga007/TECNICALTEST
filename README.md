# Catbreeds

App de razas de gatos sobre [TheCatAPI](https://thecatapi.com), construida con Flutter y clean architecture.

Tres pantallas: **Splash** → **Landing** (listado de razas) → **Detail** (ficha de la raza).

---

## Estado del proyecto

Este repositorio está en **modernización activa**: nació sobre Flutter 3.16.7 y se está llevando a **Flutter 3.44.9** en fases independientes, cada una compilable, testeable y revisable por separado.

> **Nota sobre la versión objetivo:** el pedido original fue "Flutter 3.40", pero **3.40 nunca salió como stable** — solo existió como `3.40.0-0.1.pre` y `3.40.0-0.2.pre` en el canal beta de dic 2025. La línea stable fue `3.38.10` → `3.41.0` (feb 2026) → `3.44.9` (ago 2026). Se migra a **3.44.9 stable**.

### Hoja de ruta

| # | Fase | Estado |
|---|---|---|
| 0 | Higiene, baseline y `.gitignore` | ✅ Hecha |
| 1 | Toolchain 3.44.9 con fvm (sin refactors) | ✅ Hecha |
| 2 | Costuras de testabilidad + red de regresión + bugs | ⬜ Pendiente |
| 3 | Dart 3: sealed classes + pattern matching | ⬜ Pendiente |
| 4 | Data layer: freezed, entidad inmutable, N+1, secretos | ⬜ Pendiente |
| 5 | DI: kiwi → get_it + injectable | ⬜ Pendiente |
| 6 | Persistencia: hydrated_bloc + caché TTL | ⬜ Pendiente |
| 7 | Design system: ThemeData M3, tokens, dark mode, l10n | ⬜ Pendiente |
| 8 | Responsive adaptativo real (fuera `flutter_screenutil`) | ⬜ Pendiente |
| 9 | Dedupe, componentes reutilizables, CI y cobertura | ⬜ Pendiente |

El orden no es arbitrario. El upgrade de SDK va primero porque al revés es **imposible**: `freezed 3.x`, `injectable 3.x` y `flutter_lints 6` exigen Dart ≥3.8 y `hydrated_bloc 11` exige `bloc ^9`, mientras Flutter 3.16.7 trae Dart 3.2 — `pub get` simplemente falla. Los tests van en la Fase 2, no al final, porque las fases 3-8 son justo las que cambian comportamiento en silencio y hacerlas sin red de regresión sería a ciegas.

---

## Arquitectura

Clean architecture por feature, con las tres capas separadas:

```
lib/
├── core/                      # Transversal: widgets comunes, helpers, DI, tema
│   ├── common_widgets/        # Componentes reutilizables
│   ├── config/                # Helpers, endpoints, responsive, tema
│   └── injector/              # Inyección de dependencias (kiwi → get_it en F5)
├── features/
│   ├── splash/
│   ├── landing_cats/
│   │   ├── data/              # datasource · models · repository (impl)
│   │   ├── domain/            # entities · repository (contrato) · use_cases
│   │   └── presentation/      # bloc · pages · widgets
│   └── detail_cat/
└── routers/                   # go_router
```

- **Estado:** BLoC (`flutter_bloc`)
- **Navegación:** `go_router`, rutas declarativas anidadas
- **Errores:** `Either<Failure, Success>` (`either_dart`)
- **DI:** `kiwi` con codegen (migra a `get_it` + `injectable` en la Fase 5)

---

## Requisitos

| | Versión |
|---|---|
| Flutter | **3.44.9** (stable) |
| Dart | **3.12.2** |
| JDK (solo Android) | **17** o **21** — LTS |
| Xcode (solo iOS/macOS) | 26.x |
| Plataformas soportadas | Android · iOS · macOS · Web |

La versión de Flutter se gestiona con **[fvm](https://fvm.app)**, no con el Flutter global. El SDK está pineado en `.fvm/fvm_config.json`.

```bash
# Instalar fvm si no lo tienes
brew tap leoafarias/fvm && brew install fvm

# Instalar y activar la versión pineada del proyecto
fvm install
fvm flutter --version    # debe reportar 3.44.9
```

**Importante:** usa siempre el prefijo `fvm`, para que los comandos corran contra la versión pineada y no contra el Flutter que tengas en el `PATH`:

```bash
fvm flutter pub get
fvm flutter run
fvm flutter test
fvm flutter analyze
fvm dart format .
fvm dart run build_runner build --delete-conflicting-outputs
```

### JDK para Android

AGP 8.x requiere JDK 17+. Si tu `java -version` por defecto no es 17 ni 21, apúntalo explícitamente:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
fvm flutter build apk --debug
```

---

## Ejecutar

```bash
fvm flutter pub get

fvm flutter run                 # dispositivo/simulador por defecto
fvm flutter run -d macos        # ventana redimensionable: útil para probar breakpoints
fvm flutter run -d chrome
```

---

## Changelog de modernización

### Fase 0 — Higiene y línea base

Limpieza previa al upgrade, para no arrastrar código muerto a la migración.

**Eliminado (0 usos, verificado por grep):**
- `core/config/helpers/responsive/responsive_box.dart` y `context_responsive_extension.dart` — el "sistema responsive" que el README anterior anunciaba, con **cero** llamadas en todo `lib/`.
- Los getters `isMobile` / `isAppleDevice` / `isDesktop` de `responsive.dart`. Además de no usarse, `isAppleDevice` y `isDesktop` llamaban `Platform.isMacOS` **sin guard `kIsWeb`**, así que habrían lanzado en web (`isMobile` sí tenía el guard — la inconsistencia era el bug). Quitarlos también saca `dart:io` del archivo.
- `AppCatsResponsiveApp.designSizeLarge` — declarado y nunca referenciado.
- `AppCatsColor.lightBlue` — sin usos, y de paso elimina un `Colors.blue.value` que está deprecado en Flutter moderno (→ `toARGB32()`).
- `url_launcher` (dependencia + import + el método `openUrl()` de `DetailCatPage`, que nunca se invocaba) y un import de `google_fonts` sin usar en el mismo archivo.

**Corregido:**
- Identidad de la app. El `title` del `MaterialApp` decía `'enMedallo'` — copy-paste de otro proyecto. Y el `applicationId` / `PRODUCT_BUNDLE_IDENTIFIER` era `com.example.*`, que **Google Play rechaza**. Ahora `com.jhonzuluaga.catbreeds`, con el paquete Kotlin movido en consecuencia. Nombre visible unificado a "Catbreeds" en `AndroidManifest.xml` e `Info.plist`.
- Añadido `.gitignore`, que **no existía** (el repo trackeaba 104 archivos sin filtro). Incluye `coverage/`, `env/*.json` (secretos vía `--dart-define-from-file`, Fase 4), `.fvm/versions/` y `**/failures/` (goldens fallidos, Fase 8).

**Deliberadamente NO tocado:** los typos `"LigthGreen"`/`"LigthGrey"` de `AppCatsColor` y los nombres `_configureAuthsModule` de kiwi. Esos archivos se eliminan en las fases 5 y 7 — arreglarlos ahora sería churn puro.

### Fase 1 — Toolchain 3.44.9

Upgrade **puro**: cero cambios de arquitectura, para que un fallo del toolchain nativo no se confunda con un refactor propio. Va primero porque al revés es imposible — `freezed 3.x`, `injectable 3.x` y `flutter_lints 6` exigen Dart ≥3.8 y `hydrated_bloc 11` exige `bloc ^9`, mientras 3.16.7 traía Dart 3.2.

**SDK y dependencias.** `.fvm/fvm_config.json` de `3.16.7` → `3.44.9`; `environment` a `sdk: ^3.12.0` / `flutter: '>=3.44.0'`. Las versiones se resolvieron con `pub upgrade --major-versions` en lugar de fijarlas a mano: `flutter_bloc` 8→**9.1.1**, `go_router` 13→**17.4.0**, `google_fonts` 5→**8.2.1**, `kiwi` 4→**5.0.1**, `flutter_lints` 2→**6.0.0**.

Efecto secundario relevante: la resolución **eliminó `win32 5.2.0`** del árbol. Esa transitiva (vía `google_fonts` → `path_provider`) usaba `UnmodifiableUint8ListView`, borrado en Dart 3.4, y por sí sola impedía compilar el proyecto en cualquier Flutter moderno.

`kiwi_generator` sigue reteniendo `analyzer` en 6.4.1 frente al 14.1.0 disponible; el codegen funciona, y esa deuda se salda en la Fase 5 al cambiar a `get_it` + `injectable`.

**APIs de Dart.** `flutter analyze` reportó solo 6 `info` y **cero errores** — el código resistió bien el salto de 28 versiones menores. Cinco se resolvieron con `dart fix --apply` (`MaterialStatePropertyAll` → `WidgetStatePropertyAll`, super parameters en `CatBreedModel`, anotaciones de tipo en el splash). El sexto se corrigió a mano, y es el cambio de comportamiento más importante de esta fase:

> **Se eliminó el override de accesibilidad.** `app_cats_responsive.dart` envolvía la app en un `MediaQuery(...copyWith(textScaleFactor: 1.0, boldText: false))`. **No se migró** a `TextScaler`: el propósito de ese código era anular el escalado de texto y la negrita del sistema, o sea desactivar dos ajustes de accesibilidad del usuario; migrarlo habría conservado el bug con sintaxis nueva. Se borró. Por la misma razón cayó un `alwaysUse24HourFormat: false` en `main.dart`, que ignoraba el locale para formatear horas que la app nunca muestra.
>
> **Consecuencia esperada:** la app ahora respeta el tamaño de fuente del SO, lo que **expondrá desbordes reales de layout**. Arreglarlos es trabajo de la Fase 8, donde se prueba a 1.0 / 1.5 / 2.0.

También se quitó `useInheritedMediaQuery` de `ScreenUtilInit` (workaround para Flutter <3.10, hoy no-op) y se aplicó `dart format`, que con `dart_style` 3.x reformateó 24 archivos.

**Toolchain Android.** De AGP 7.3.0 / Gradle 7.5 / Kotlin 1.7.10 / Java 8 a **AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 / Java 17**. Además: `compileSdkVersion` → `compileSdk`, se borró el `buildscript {}` con el classpath manual de Kotlin, `rootProject.buildDir` → `layout.buildDirectory` (la propiedad mutable desapareció en Gradle 9), y se quitó `android.enableJetifier` (eliminado en AGP 8, y solo servía para dependencias pre-AndroidX que este proyecto no tiene). Se eliminó también el boilerplate de `localProperties` para leer `versionCode`/`versionName`, que el Flutter Gradle Plugin ya expone.

> **Sobre por qué AGP 8.11.1 y no 9.0.1.** El template de Flutter 3.44.9 ships AGP 9.0.1 / Gradle 9.1.0 / Kotlin 2.3.20 en Kotlin DSL. Pero el `DependencyVersionChecker` del propio Flutter marca error bajo AGP 8.6 / Gradle 8.7 / KGP 2.0 y advertencia bajo AGP 8.11.1 / Gradle 8.14 / KGP 2.2.20. Elegir los umbrales de advertencia deja el build **libre de warnings** sin arrastrar un major de AGP ni una conversión a `.kts` — que contradiría el mandato de que esta fase sea un upgrade puro y un diff revisable. AGP 9 + Kotlin DSL queda como follow-up deliberado.

Dos cosas que el template moderno trae y al proyecto le faltaban: `android:taskAffinity=""` en la `MainActivity` y el bloque `<queries>` de `PROCESS_TEXT` que necesita el `ProcessTextPlugin` del engine.

**iOS.** Deployment target 12.0 → **13.0** (`project.pbxproj`, `AppFrameworkInfo.plist`) y `platform :ios, '13.0'` activado en el `Podfile`. Flutter aplicó además sus migraciones automáticas: `@UIApplicationMain` → `@main` y el `customLLDBInitFile` del scheme.

**Nuevas plataformas: macOS y Web.** El proyecto solo tenía `android/` e `ios/`, así que el breakpoint *expanded* y el `NavigationRail` de la Fase 8 eran indemostrables. Con macOS se puede redimensionar la ventana de 390 a 1440 px y ver los breakpoints en vivo. La identidad se alineó con la de la Fase 0 (`Catbreeds`, `com.jhonzuluaga.catbreeds`).

**Verificado:** `analyze` sin issues, `dart format` sin diff, y las **cuatro** plataformas compilan — `build apk --debug`, `build ios --no-codesign`, `build macos --debug`, `build web`.

**Nota honesta sobre el baseline.** La Fase 0 preveía capturas de la app corriendo en 3.16.7 como referencia visual. No fue posible: Flutter 3.16.7 (ene 2024) no compila contra Xcode 26.6, y el `pubspec.lock` original fijaba `win32 5.2.0`, que ni siquiera compila en Dart moderno — el proyecto tal como estaba commiteado **no era construible** en un entorno actual. La referencia visual se toma entonces al cierre de esta fase (post-upgrade, pre-rediseño), que de hecho aísla mejor los cambios de las fases 7 y 8, ya que no mezcla diferencias del SDK.
