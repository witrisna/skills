# OIDC Module Configuration Reference

The `Oidc` module is an optional but recommended addition to the `Journey` instance. It enables
OpenID Connect token exchange after a successful Journey authentication.

---

## Basic Configuration

```kotlin
module(Oidc) {
    clientId          = "your-client-id"
    discoveryEndpoint = "https://<tenant>.forgeblocks.com/am/oauth2/<realm>/.well-known/openid-configuration"
    scopes            = mutableSetOf("openid", "email", "profile", "phone", "address")
    redirectUri       = "org.forgerock.demo:/oauth2redirect"
}
```

---

## All Configuration Properties

| Property              | Type                | Required | Description                                                         |
|-----------------------|---------------------|----------|---------------------------------------------------------------------|
| `clientId`            | `String`            | ✅        | OAuth2 client ID registered in AIC                                 |
| `discoveryEndpoint`   | `String`            | ✅        | OIDC discovery URL (`.well-known/openid-configuration`)            |
| `scopes`              | `MutableSet<String>`| ✅        | Requested OAuth2 scopes (always include `openid`)                  |
| `redirectUri`         | `String`            | ✅        | Custom scheme URI matching your `AndroidManifest.xml` intent filter |
| `clientSecret`        | `String`            | ❌        | Only for confidential clients (avoid in mobile apps)               |
| `acrValues`           | `String`            | ❌        | Authentication Context Class Reference values                       |
| `loginHint`           | `String`            | ❌        | Pre-fill the username hint in the authorization request            |
| `nonce`               | `String`            | ❌        | Override automatic nonce generation                                 |
| `additionalParameters`| `Map<String,String>`| ❌        | Extra query parameters to add to the authorization request         |

---

## Storage Configuration

The `storage { }` block inside `module(Oidc)` controls how tokens are persisted.

```kotlin
module(Oidc) {
    // ... required fields ...
    storage {
        fileName           = "oidc_tokens"      // DataStore file name
        keyAlias           = "MyKeyAlias"        // Enables EncryptedDataStore (AndroidKeyStore)
        strongBoxPreferred = true                // Prefer hardware-backed StrongBox
        cacheStrategy      = CacheStrategy.CACHE_ON_FAILURE
    }
}
```

### CacheStrategy Options

| Value                  | Behaviour                                                   |
|------------------------|-------------------------------------------------------------|
| `NO_CACHE`             | No in-memory cache; always read from disk                   |
| `CACHE_ON_FAILURE`     | Cache in memory only when disk read fails *(default)*       |
| `CACHE`                | Always cache in memory, even after successful disk reads    |

> ⚠️ In-memory cached data is **plain text**. On rooted devices with memory dump capability,
> tokens could be exposed. Use `NO_CACHE` in high-security scenarios.

---

## Session Module (Optional)

The `Session` module allows you to configure SSO session token storage separately:

```kotlin
module(Session) {
    storage {
        strongBoxPreferred = false
        cacheStrategy      = CacheStrategy.CACHE_ON_FAILURE
    }
}
```

---

## Redirect URI Setup

### AndroidManifest.xml
```xml
<activity android:name=".MainActivity"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="${appRedirectUriScheme}" />
    </intent-filter>
</activity>
```

### build.gradle.kts
```kotlin
android {
    defaultConfig {
        manifestPlaceholders["appRedirectUriScheme"] = "org.forgerock.demo"
    }
}
```

The `redirectUri` in the OIDC config must match: `org.forgerock.demo:/oauth2redirect`

---

## PingOne AIC Client Registration

Ensure your OAuth2 client in AIC is configured as:

- **Client type**: Public (for mobile apps)
- **Grant types**: Authorization Code
- **Token endpoint auth method**: `none`
- **Redirect URIs**: must include your redirect URI (e.g. `org.forgerock.demo:/oauth2redirect`)
- **Scopes**: must include all scopes requested in the SDK config

