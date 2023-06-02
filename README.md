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

### Considerations
The Demo is meant only to present a possible implementation of our design work, it provides only a few set of functionalities; in particular:
- it shows the process of creation and storage of passkeys
- it shows how a passkey stored only in the server-side wallet can be retrieved and synchronized inside the local wallet
- allows to perform authentication request validation and response
- it shows the message exchanged bewteen client and server in the various operations

### Licenses

The Demo will perform the following operations, in this order:

1. Ask user permission (fingeprint) to create a new `Wallet` istance with:
    - a new public-private key-pair
    - an empty set of passkeys
2. Ask user permission (fingerprint) to register two demo passkeys inside the Wallet (`demoData/demoPasskey.dart`)
3. Show available passkeys list:
    - each can be inspected and used to perform authentication
4. Locally synchronize the wallet with a Passkey only available server-side:

- bluetooth transmission is not yet implemented at this point
    in this use case we assume the following:
  - server-side passkey to be already transmitted from the original wallet to the actual considered user's one
  - e2e key to be already transmitted from the original device to the actually considered one
- the aforementioned assumptions are considered in particular for the live Demo demonstration purpose, in order to define a reasonable level of trade-off between what is implemented and actually shown without mocking features or, on the other hand, presenting trivial functionalities

### Future Developments

The Demo, as already said, presents a set of reduced functionalities and is far from being a mature and ready-to-deployment application; next developments will regard definition of a one-user to many-wallets schema, and the design of a clever relationship between those entities

### Licenses
