---
name: ping-journey-android-auth
description: Android Authentication with Ping Identity Journey (Jetpack Compose + MVVM)
parameters:
  - name: serverUrl
    description: "Base URL of your PingOne AIC tenant (e.g. https://your-tenant.forgeblocks.com/am)"
    required: true
    example: "https://your-tenant.forgeblocks.com/am"
  - name: realm
    description: "PingOne AIC realm name"
    required: false
    default: "alpha"
    example: "alpha"
  - name: clientId
    description: "OAuth2 Client ID registered in PingOne AIC for this Android app"
    required: true
    example: "my-android-client"
  - name: discoveryEndpoint
    description: "Full OIDC discovery endpoint URL for the realm"
    required: true
    example: "https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
  - name: scopes
    description: "Space-separated list of OAuth2 scopes to request"
    required: false
    default: "openid email profile phone"
    example: "openid email profile"
  - name: redirectUri
    description: "OAuth2 redirect URI registered in the client application"
    required: false
    default: "org.forgerock.demo:/oauth2redirect"
    example: "com.myapp.android:/oauth2redirect"
  - name: cookieName
    description: "SSO cookie name for the realm (leave blank to omit)"
    required: false
    default: ""
    example: "iPlanetDirectoryPro"
  - name: journeyName
    description: "Name of the Journey/Tree to invoke on start"
    required: false
    default: "Login"
    example: "UsernamePassword"
---
# Skill: Android Authentication with Ping Identity Journey (Jetpack Compose + MVVM)

## Metadata

| Field       | Value                                                       |
|-------------|-------------------------------------------------------------|
| Name        | ping-journey-android-auth                                   |
| Version     | 2.0.0-beta1                                                 |
| Language    | Kotlin                                                      |
| Framework   | Android, Jetpack Compose, AndroidX ViewModel                |
| SDK         | Ping Identity Journey SDK (`com.pingidentity.sdks:journey`) |
| Pattern     | MVVM (Model-View-ViewModel)                                 |
| Min SDK     | 29                                                          |
| Compile SDK | 36                                                          |

---

## Overview

This skill adds a complete **authentication flow** to an Android application using Jetpack Compose
and the MVVM pattern. It uses the **Ping Identity Journey SDK** to authenticate users against
**PingOne AIC (Advanced Identity Cloud)**.

The implementation covers:
- Journey instance configuration (server URL, realm, OIDC module)
- MVVM state management with `StateFlow`
- Composable UI that renders dynamic callback nodes
- Handling all core callback types (username, password, text, choice, etc.)
- Success, error and failure node handling
- Logout support

---

## Prerequisites

### 1. Gradle Dependencies

Add the following to the **app-level** `build.gradle.kts`:

```kotlin
dependencies {
    // Ping Identity Journey SDK
    implementation("com.pingidentity.sdks:journey:<version>")

    // Jetpack Compose BOM
    val composeBom = platform("androidx.compose:compose-bom:<bom_version>")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.activity:activity-compose")
    implementation("androidx.navigation:navigation-compose")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose")

    // DataStore (for token/session persistence)
    implementation("androidx.datastore:datastore-preferences")
}
```

> See `gradle/libs.versions.toml` in this repo for the exact version catalog entries used in the
> sample app.

### 2. AndroidManifest.xml

Add the redirect URI scheme as an intent filter (required for OAuth2 redirect):

```xml
<activity android:name=".MainActivity" ...>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="${appRedirectUriScheme}" />
    </intent-filter>
</activity>
```

In `build.gradle.kts` `defaultConfig`:

```kotlin
manifestPlaceholders["appRedirectUriScheme"] = "org.forgerock.demo"
```

---

## Required Configuration

> **Agent instruction:** Before generating any file, collect the values below from the user.
> Ask for all `required` parameters up front in a single prompt. For optional parameters, show the
> default and ask whether the user wants to override it. Do **not** proceed to Step 1 until every
> required parameter has a non-empty value.

### Parameters to collect

| Parameter | Required | Default | Description |
|---|---|---|---|
| `serverUrl` | ✅ Yes | — | Base URL of the PingOne AIC tenant (e.g. `https://your-tenant.forgeblocks.com/am`) |
| `realm` | No | `alpha` | Realm name inside the tenant |
| `clientId` | ✅ Yes | — | OAuth2 Client ID registered in PingOne AIC for this Android app |
| `discoveryEndpoint` | ✅ Yes | — | Full OIDC discovery endpoint URL (`.well-known/openid-configuration`) |
| `scopes` | No | `openid email profile phone` | Space-separated OAuth2 scopes to request |
| `redirectUri` | No | `org.forgerock.demo:/oauth2redirect` | OAuth2 redirect URI registered in PingOne AIC for the client |
| `cookieName` | No | *(omitted)* | SSO cookie name for the realm; omit the `cookie` line if blank |
| `journeyName` | No | `Login` | Name of the Journey/Tree to invoke on start |

### Suggested prompts

Use the following (or equivalent) questions when the user invokes this skill:

```
Before I generate the files, I need a few details about your PingOne AIC setup:

1. 🌐 Server URL          — What is your PingOne AIC tenant base URL?
                             e.g. https://your-tenant.forgeblocks.com/am
2. 🔑 Client ID           — What is the OAuth2 Client ID for this Android app?
3. 🔍 Discovery Endpoint  — What is the full OIDC discovery endpoint URL?
                             e.g. https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration
4. 🏛️ Realm              — Which realm? (press Enter to use the default: alpha)
5. 📋 Scopes              — Which OAuth2 scopes? (default: openid email profile phone)
6. 🔀 Redirect URI        — What is the redirect URI? (default: org.forgerock.demo:/oauth2redirect)
7. 🍪 Cookie name         — SSO cookie name? (leave blank to omit)
8. 🗺️ Journey name       — Which Journey/Tree to start? (default: Login)
```

### Validation rules

- `serverUrl` must start with `https://` and **not** end with a trailing `/`.
- `discoveryEndpoint` must end with `/.well-known/openid-configuration`.
- `clientId` must be non-empty.
- `redirectUri` must follow `<scheme>:/<path>` format; the scheme must match the
  `manifestPlaceholders["appRedirectUriScheme"]` value used in `build.gradle.kts`.
- If `scopes` does not include `openid`, prepend it automatically and warn the user.
- If `discoveryEndpoint` domain differs from `serverUrl` domain, warn the user but proceed.

---

## Implementation Steps

### Step 1 — Configure the Journey Instance

Create a file `JourneyConfig.kt` (or add to your DI module). See `assets/JourneyConfig.kt.template`.

> **Agent instruction:** Substitute all `<parameter>` placeholders below with the values collected
> in the **Required Configuration** section. Omit the `cookie` line entirely if `cookieName` is
> blank.

```kotlin
val journey = Journey {
    logger = Logger.STANDARD
    serverUrl = "<serverUrl>"           // collected: serverUrl
    realm = "<realm>"                   // collected: realm  (default: "alpha")
    cookie = "<cookieName>"             // omit this line if cookieName is blank

    module(Oidc) {
        clientId = "<clientId>"         // collected: clientId
        discoveryEndpoint = "<discoveryEndpoint>"  // collected: discoveryEndpoint
        scopes = mutableSetOf(<scopes>) // collected: scopes — split by space, quote each token
        redirectUri = "<redirectUri>"   // collected: redirectUri
    }
}
```

**Example** (filled with real values):

```kotlin
val journey = Journey {
    logger = Logger.STANDARD
    serverUrl = "https://your-tenant.forgeblocks.com/am"
    realm = "alpha"
    cookie = "iPlanetDirectoryPro"  // omit if no cookie name was provided

    module(Oidc) {
        clientId = "my-android-client"
        discoveryEndpoint =
            "https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
        scopes = mutableSetOf("openid", "email", "profile", "phone")
        redirectUri = "org.forgerock.demo:/oauth2redirect"
    }
}
```

> The `redirectUri` scheme must match `manifestPlaceholders["appRedirectUriScheme"]` in
> `build.gradle.kts` (see Prerequisites § AndroidManifest.xml).

---

### Step 2 — Create the Auth State

Create `AuthState.kt`. See `assets/AuthState.kt.template`.

```kotlin
import com.pingidentity.orchestrate.Node

data class AuthState(
    val node: Node? = null,
    val counter: Int = 0   // Used to trigger recomposition when node is same object
)
```

---

### Step 3 — Create the Auth ViewModel

Create `AuthViewModel.kt`. See `assets/AuthViewModel.kt.template`.

```kotlin
class AuthViewModel(private val journeyName: String) : ViewModel() {

    var state = MutableStateFlow(AuthState())
        private set

    var loading = MutableStateFlow(false)
        private set

    init { start() }

    fun start() {
        loading.update { true }
        viewModelScope.launch {
            val node = journey.start(journeyName)
            state.update { it.copy(node = node) }
            loading.update { false }
        }
    }

    fun next(node: ContinueNode) {
        loading.update { true }
        viewModelScope.launch {
            val next = node.next()
            state.update { it.copy(node = next) }
            loading.update { false }
        }
    }

    fun refresh() {
        state.update { it.copy(counter = it.counter + 1) }
    }

    fun logout(onCompleted: () -> Unit) {
        viewModelScope.launch { journey.user()?.logout() }
        onCompleted()
    }

    companion object {
        fun factory(journeyName: String): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    AuthViewModel(journeyName) as T
            }
    }
}
```

---

### Step 4 — Create the Callback Node Composable

Create `CallbackNode.kt` which renders each callback in a `ContinueNode`. See
`assets/CallbackNode.kt.template` for the full implementation.

The pattern is:

```kotlin
@Composable
fun CallbackNode(
    continueNode: ContinueNode,
    onNodeUpdated: () -> Unit,
    onNext: () -> Unit,
) {
    var showNext = true

    continueNode.callbacks.forEach { callback ->
        when (callback) {
            is NameCallback -> NameCallbackField(callback, onNodeUpdated)
            is PasswordCallback -> PasswordCallbackField(callback, onNodeUpdated)
            is TextInputCallback -> TextInputCallbackField(callback, onNodeUpdated)
            is TextOutputCallback -> TextOutputCallbackField(callback)
            is ChoiceCallback -> ChoiceCallbackField(callback, onNodeUpdated)
            is ConfirmationCallback -> {
                showNext = false
                ConfirmationCallbackField(callback, onNext)
            }
            is PollingWaitCallback -> {
                PollingWaitCallbackField(callback, onNext)
            }
            // Add more callbacks as needed
        }
    }

    if (showNext) {
        Button(onClick = onNext) { Text("Next") }
    }
}
```

> See `references/callbacks.md` for the full list of supported callbacks and their properties.

---

### Step 5 — Create the Auth Screen Composable

Create `AuthScreen.kt`. See `assets/AuthScreen.kt.template`.

```kotlin
@Composable
fun AuthScreen(
    viewModel: AuthViewModel,
    onSuccess: () -> Unit,
) {
    BackHandler { viewModel.start() }

    val state by viewModel.state.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier.fillMaxSize()
    ) {
        if (loading) CircularProgressIndicator()

        when (val node = state.node) {
            is ContinueNode -> CallbackNode(
                continueNode = node,
                onNodeUpdated = { viewModel.refresh() },
                onNext = { viewModel.next(node) }
            )
            is FailureNode -> ErrorCard(message = node.cause.message ?: "Unknown error")
            is ErrorNode -> ErrorCard(message = node.message)
            is SuccessNode -> LaunchedEffect(true) { onSuccess() }
            null -> {}
        }
    }
}
```

---

### Step 6 — Wire Navigation

In your `NavHost`, add:

```kotlin
composable("auth/{journeyName}", arguments = listOf(
    navArgument("journeyName") { type = NavType.StringType }
)) { backStack ->
    val name = backStack.arguments?.getString("journeyName") ?: "Login"
    val vm: AuthViewModel = viewModel(factory = AuthViewModel.factory(name))
    AuthScreen(viewModel = vm) {
        navController.navigate("home") {
            popUpTo("auth/{journeyName}") { inclusive = true }
        }
    }
}
```

---

### Step 7 — Entry Point in MainActivity

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MyAppTheme {
                val navController = rememberNavController()
                NavHost(navController = navController, startDestination = "auth/Login") {
                    // ... routes
                }
            }
        }
    }
}
```

---

## Node Types Reference

| Node Type      | When Triggered                           | Action                                         |
|----------------|------------------------------------------|------------------------------------------------|
| `ContinueNode` | Journey has more steps                   | Render callbacks, call `node.next()` to proceed |
| `ErrorNode`    | Server returned HTTP 4xx/5xx             | Show `node.message` to user                    |
| `FailureNode`  | Network error or unexpected SDK failure  | Show generic error, log `node.cause`           |
| `SuccessNode`  | Authentication succeeded                 | Navigate to authenticated screen               |

---

## Post-Authentication Operations

```kotlin
// Get access token
val user = journey.user()
val accessToken = user?.accessToken()

// Fetch user info (OIDC userinfo endpoint)
val userinfo = user?.userinfo()

// Revoke tokens
user?.revoke()

// Full logout (clears session + tokens)
user?.logout()
```

---

## File Structure Created By This Skill

```
<feature_package>/
├── JourneyConfig.kt                              # Journey + OIDC configuration (singleton)
├── auth/
│   ├── AuthState.kt                              # UI state data class
│   ├── AuthViewModel.kt                          # ViewModel: orchestrates journey flow
│   ├── AuthScreen.kt                             # Root composable: collects state, renders nodes
│   └── callback/
│       ├── CallbackNode.kt                       # Dispatches ALL callbacks to composables
│       ├── CallbackFields.kt                     # Core + optional-module callback UIs:
│       │                                         #   NameCallback, PasswordCallback,
│       │                                         #   ValidatedUsername/PasswordCallback,
│       │                                         #   TextInput/OutputCallback,
│       │                                         #   SuspendedTextOutputCallback,
│       │                                         #   ChoiceCallback, ConfirmationCallback,
│       │                                         #   BooleanAttributeInputCallback,
│       │                                         #   NumberAttributeInputCallback,
│       │                                         #   StringAttributeInputCallback,
│       │                                         #   TermsAndConditionsCallback,
│       │                                         #   ConsentMappingCallback, KbaCreateCallback,
│       │                                         #   PollingWaitCallback,
│       │                                         #   DeviceProfileCallback,        (:device-profile)
│       │                                         #   ReCaptchaEnterpriseCallback,  (:recaptcha-enterprise)
│       │                                         #   SelectIdpCallback,            (:external-idp)
│       │                                         #   IdpCallback,                  (:external-idp)
│       │                                         #   PingOneProtectInitialize,     (:protect)
│       │                                         #   PingOneProtectEvaluation,     (:protect)
│       │                                         #   FidoRegistration,             (:mfa:fido)
│       │                                         #   FidoAuthentication            (:mfa:fido)
│       ├── DeviceBindingCallbackViewModel.kt     # ViewModel for PIN-based device binding
│       ├── DeviceBindingCallbackField.kt         # UI + PinCollectorDialog  (:mfa:binding)
│       ├── DeviceSigningVerifierCallbackViewModel.kt  # ViewModel for sign + PIN + UserKey
│       └── DeviceSigningVerifierCallbackField.kt # UI + UserKeyDialog       (:mfa:binding)
```

---

## Optional Module Dependencies

Add these to `build.gradle.kts` only for the callbacks you need:

```kotlin
// Device profile collection
implementation(project(":foundation:device:device-profile"))  // or published artifact

// reCAPTCHA Enterprise
implementation(project(":recaptcha-enterprise"))

// Social / External IdP login
implementation(project(":external-idp"))

// PingOne Protect risk evaluation
implementation(project(":protect"))

// FIDO2 / WebAuthn passkeys
implementation(project(":mfa:fido"))
implementation(libs.play.services.fido)   // Google FIDO2 service

// Device binding (cryptographic key bound to user account)
implementation(project(":mfa:binding"))
```

---

## References

- `references/journey-sdk.md` — Journey SDK API summary
- `references/callbacks.md` — Complete callback type reference with all 26 callbacks
- `references/oidc-config.md` — OIDC module configuration options
- `assets/` — Kotlin file templates ready to copy-paste
