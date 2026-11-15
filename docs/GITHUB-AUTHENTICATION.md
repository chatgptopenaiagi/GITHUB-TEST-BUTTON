# Authentication

Public diagnostics do not require authentication. A public API success does not prove identity, private repository access, or push permission.

Windows and the Python CLI can inspect the user's existing `gh` installation and request the authenticated `/user` identity. GTB does not change global Git credentials or copy credentials between devices. The project publisher's account is not a built-in user identity.

## Android boundary

The beta's Android interface performs public diagnostics independently. Authenticated mobile operation is pending registration and integration validation; no successful mobile authentication is claimed.

GitHub's [OAuth documentation](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps) currently documents S256 PKCE, state validation, redirect handling, and a client secret required at the authorization-code exchange endpoint. A secret must never be embedded in a native APK. A future authorization-code integration therefore needs a registered application and a secure server-side exchange, or a separately reviewed supported native authorization strategy.

Registration checklist for the account owner: create a dedicated application, choose the minimum scopes, register the exact production callback and application homepage, supply the public client ID, and provision any server-side secret outside this repository. Validate state and PKCE, use the external browser, store supported credentials in Android secure storage, validate `/user` after authorization, and test revocation/expiry. Do not distribute a guessed client ID or a shared personal token.

GitHub also documents a device authorization flow that requires an application registration with device flow enabled. Its polling intervals and expiry must be respected. This beta does not pretend that an unregistered client is authorized.
