# Trustify Demo

## About

This Demo Project is meant to demonstrate in a practical way a proof-of-concept of the design work and the result achieved by our group during the Challenge time period.

### Demo structure

The Demo consists in two essential modules:

1. **Client:** a [Flutter](https://flutter.dev/) application allowing the user to perform all Passkeys-related operations such as:
    - Creation
    - Secure Storage of passkey material
    - Authentication request
    - Bluetooth transmission of end-to-end key
2. **Server:** an [Express](https://expressjs.com/it/) server allowing the user to securely store its wallet outside its personal device while, at the same time, allowing:
    - Local synchronization of a server-side-only existing passkey; this can be useful in case of:
        - local corruption of the passkey
        - exchange of the same passkey between two wallets belonging to the same user
    - Authentication validation
    - registration of a new wallet

### Licenses

