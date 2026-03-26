# Callback Types Reference

Callbacks are returned inside a `ContinueNode` during the Journey authentication flow.
Access them via `continueNode.callbacks`.

---

## Core Journey Callbacks

### NameCallback
Collects a **username** or generic name input.

| Property | Type     | Description                     |
|----------|----------|---------------------------------|
| `prompt` | `String` | Label to display to the user    |
| `name`   | `String` | Read/write: the user's input    |

```kotlin
is NameCallback -> {
    callback.name = "johndoe"
}
```

---

### PasswordCallback
Collects a **password** or one-time passcode.

| Property   | Type     | Description                   |
|------------|----------|-------------------------------|
| `prompt`   | `String` | Label to display              |
| `password` | `String` | Write-only: the user's secret |

```kotlin
is PasswordCallback -> {
    callback.password = "s3cr3t"
}
```

---

### ValidatedUsernameCallback
Collects a username **with server-side policy validation**.

| Property   | Type     | Description                        |
|------------|----------|------------------------------------|
| `prompt`   | `String` | Label                              |
| `username` | `String` | Read/write: validated username     |
| `policies` | `List`   | Optional: validation policy hints  |

---

### ValidatedPasswordCallback
Collects a password **with server-side policy validation**.

| Property   | Type     | Description                         |
|------------|----------|-------------------------------------|
| `prompt`   | `String` | Label                               |
| `password` | `String` | Write-only                          |
| `policies` | `List`   | Optional: validation policy hints   |

---

### TextInputCallback
Collects generic **text input** (e.g., nickname, OTP, custom field).

| Property      | Type     | Description                  |
|---------------|----------|------------------------------|
| `prompt`      | `String` | Label                        |
| `defaultText` | `String` | Pre-filled default value     |
| `value`       | `String` | Read/write: the user's input |

---

### TextOutputCallback
Displays a **server-provided message** (no user input required).

| Property        | Type  | Description                                      |
|-----------------|-------|--------------------------------------------------|
| `message`       | `String` | The text to display                           |
| `messageType`   | `Int` | `0` = INFO, `1` = WARNING, `2` = ERROR, `4` = SCRIPT |

```kotlin
is TextOutputCallback -> {
    Text(callback.message)
}
```

---

### ChoiceCallback
Allows the user to select **one option from a list**.

| Property         | Type           | Description                             |
|------------------|----------------|-----------------------------------------|
| `prompt`         | `String`       | Label                                   |
| `choices`        | `List<String>` | Available options                       |
| `defaultChoice`  | `Int`          | Index of default selection              |
| `selectedIndex`  | `Int`          | Read/write: index of selected choice    |

---

### ConfirmationCallback
Displays **action buttons** (e.g., "Submit", "Cancel"). Replaces the default Next button.

| Property   | Type           | Description                             |
|------------|----------------|-----------------------------------------|
| `prompt`   | `String`       | Optional prompt text                    |
| `options`  | `List<String>` | Button labels                           |
| `selectedIndex` | `Int`     | Read/write: which button was pressed    |

> Set `showNext = false` in your `CallbackNode` when this callback is present.

---

### BooleanAttributeInputCallback
Collects a **true/false** value (e.g., "Receive marketing emails?").

| Property | Type      | Description              |
|----------|-----------|--------------------------|
| `prompt` | `String`  | Label                    |
| `value`  | `Boolean` | Read/write: user's input |

---

### NumberAttributeInputCallback
Collects a **numeric** value.

| Property | Type     | Description              |
|----------|----------|--------------------------|
| `prompt` | `String` | Label                    |
| `value`  | `Double` | Read/write: user's input |

---

### StringAttributeInputCallback
Collects an **arbitrary string attribute** (for profile enrichment).

| Property | Type     | Description              |
|----------|----------|--------------------------|
| `prompt` | `String` | Label                    |
| `value`  | `String` | Read/write: user's input |

---

### KbaCreateCallback
Collects **Knowledge-Based Authentication** (security question & answer).

| Property          | Type           | Description                        |
|-------------------|----------------|------------------------------------|
| `prompt`          | `String`       | Instruction text                   |
| `predefinedQuestions` | `List<String>` | Questions to choose from       |
| `selectedQuestion` | `String`      | Write: question selected by user   |
| `answer`          | `String`       | Write: user's answer               |

---

### TermsAndConditionsCallback
Displays **terms & conditions** for user acceptance.

| Property  | Type     | Description                         |
|-----------|----------|-------------------------------------|
| `terms`   | `String` | The T&C text                        |
| `version` | `String` | Version identifier                  |
| `accept`  | `Boolean`| Write: whether user accepted        |

---

### ConsentMappingCallback
Prompts the user to **consent to data sharing**.

| Property       | Type     | Description                   |
|----------------|----------|-------------------------------|
| `name`         | `String` | Consent name                  |
| `displayName`  | `String` | Human-readable name           |
| `fields`       | `List`   | Fields being consented to     |
| `accept`       | `Boolean`| Write: consent decision       |

---

### PollingWaitCallback
Instructs the client to **wait** then auto-resubmit.

| Property        | Type  | Description                            |
|-----------------|-------|----------------------------------------|
| `waitTime`      | `Int` | Milliseconds to wait before advancing  |
| `message`       | `String` | Message to display while waiting    |

> Set `showNext = false`. Launch a coroutine to `delay(waitTime)` then call `onNext()`.

---

### SuspendedTextOutputCallback
Pauses authentication for **magic-link / email verification**. Similar to `TextOutputCallback` but
the journey is suspended server-side.

> Set `showNext = false`. Display the message and wait for the user to click a link in their email.

---

## Extended Module Callbacks

These require additional SDK modules as dependencies:

| Callback                          | Module              | Description                                      |
|-----------------------------------|---------------------|--------------------------------------------------|
| `DeviceProfileCallback`           | `foundation:device:device-profile` | Collects device metadata          |
| `DeviceBindingCallback`           | `mfa:binding`       | Binds device cryptographic key to user account   |
| `DeviceSigningVerifierCallback`   | `mfa:binding`       | Verifies a bound device by signing a challenge   |
| `FidoRegistrationCallback`        | `mfa:fido`          | Registers a FIDO2/WebAuthn credential            |
| `FidoAuthenticationCallback`      | `mfa:fido`          | Authenticates with FIDO2/WebAuthn                |
| `PingOneProtectInitializeCallback`| `protect`           | Initializes PingOne Protect risk evaluation      |
| `PingOneProtectEvaluationCallback`| `protect`           | Submits risk signal data                         |
| `ReCaptchaEnterpriseCallback`     | `recaptcha-enterprise` | Handles reCAPTCHA Enterprise verification     |
| `SelectIdpCallback`               | `external-idp`      | Displays external IdP selector                   |
| `IdpCallback`                     | `external-idp`      | Handles external IdP redirect flow               |

---

## UI Pattern for Callback Rendering

```kotlin
continueNode.callbacks.forEach { callback ->
    when (callback) {
        is NameCallback        -> NameCallbackField(callback, onNodeUpdated)
        is PasswordCallback    -> PasswordCallbackField(callback, onNodeUpdated)
        is TextInputCallback   -> TextInputCallbackField(callback, onNodeUpdated)
        is TextOutputCallback  -> TextOutputCallbackField(callback)
        is ChoiceCallback      -> ChoiceCallbackField(callback, onNodeUpdated)
        is ConfirmationCallback -> {
            showNext = false
            ConfirmationCallbackField(callback, onNext)
        }
        is PollingWaitCallback -> {
            // showNext = false; auto-advance after delay
        }
        is SuspendedTextOutputCallback -> {
            TextOutputCallbackField(callback)
            showNext = false
        }
        else -> { /* unknown callback: skip or log */ }
    }
}
```

