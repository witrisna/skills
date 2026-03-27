# Journey SDK API Reference

## Overview

`Journey` is the primary entry point of the Ping Identity Journey SDK. It manages the full
authentication flow against **PingOne Advanced Identity Cloud (AIC)**.

---

## Creating a Journey Instance

```kotlin
import com.pingidentity.journey.Journey
import com.pingidentity.journey.module.Oidc
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD

val journey = Journey {
    serverUrl = "https://<tenant>.forgeblocks.com/am"
    realm     = "alpha"          // Your AIC realm
    cookie    = "<cookie-name>"  // Optional: SSO cookie name
    timeout   = 30_000           // Network timeout in ms (default: 15_000)
    logger    = Logger.STANDARD  // Outputs to Android Logcat

    module(Oidc) {
        clientId          = "<client-id>"
        discoveryEndpoint = "https://<tenant>.forgeblocks.com/am/oauth2/<realm>/.well-known/openid-configuration"
        scopes            = mutableSetOf("openid", "email", "profile", "phone")
        redirectUri       = "org.forgerock.demo:/oauth2redirect"

        // Optional: encrypted storage configuration
        storage {
            fileName          = "oidc_tokens"
            keyAlias          = "myKeyAlias"   // enables AndroidKeyStore encryption
            strongBoxPreferred = true
        }
    }
}
```

---

## Starting the Authentication Flow

```kotlin
// Start a named journey (tree/flow configured in AIC admin console)
var node = journey.start("Login")

// Optional parameters
var node = journey.start("Login") {
    forceAuth = true   // Force re-authentication even with a valid session
    noSession = true   // Do not persist a session after successful authentication
}

// Resume a suspended (magic-link) journey
var node = journey.resume(uri = incomingUri)
```

---

## Navigating the Node Graph

```kotlin
when (node) {
    is ContinueNode -> {
        // Populate callbacks, then advance
        node.callbacks.forEach { /* set user input */ }
        node = node.next()
    }
    is SuccessNode  -> { /* authenticated */ }
    is ErrorNode    -> { val msg = node.message }
    is FailureNode  -> { val err = node.cause }
}
```

---

## User / Session Operations

```kotlin
import com.pingidentity.utils.Result

val user = journey.user()          // Returns User? — null if not authenticated

// Token access
when (val result = user?.token()) {
    is Result.Failure -> {
    }

    is Result.Success -> {
        val accessToken = result.value.accessToken
    }
}

val ssoToken     = user?.session()

// Fetch user info (OIDC userinfo endpoint)
when (val result = user.userinfo(false)) {
    is Result.Failure -> {
    }

    is Result.Success -> {
        val userInfo = result.value //JsonObject
    }
}      // Returns JsonObject

// Revoke tokens (keeps SSO session)
user?.revoke()

// Full logout (clears SSO session + tokens)
user?.logout()
```
---

## Node Types

| Type           | Package                             | Key Properties                        |
|----------------|-------------------------------------|---------------------------------------|
| `ContinueNode` | `com.pingidentity.orchestrate`      | `callbacks`, `header`, `description`, `pageFooter`, `submitButtonText` |
| `SuccessNode`  | `com.pingidentity.orchestrate`      | `session`, `input`                    |
| `ErrorNode`    | `com.pingidentity.orchestrate`      | `message`, `input`                    |
| `FailureNode`  | `com.pingidentity.orchestrate`      | `cause: Throwable`                    |

---

## ContinueNode Extension Properties (Journey Plugin)

These are provided by `foundation/journey-plugin`:

```kotlin
continueNode.header          // Stage header string
continueNode.description     // Stage description string
continueNode.pageFooter      // Page footer string
continueNode.submitButtonText // Custom submit button label
continueNode.callbacks       // List<Callback> - the callback instances for this node
```

---

## Imports Cheatsheet

```kotlin
import com.pingidentity.journey.Journey
import com.pingidentity.journey.module.Oidc
import com.pingidentity.journey.module.Session
import com.pingidentity.journey.start
import com.pingidentity.journey.user
import com.pingidentity.journey.session
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.SuccessNode
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.FailureNode
import com.pingidentity.orchestrate.Node
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
```

