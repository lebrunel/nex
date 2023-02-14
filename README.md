# Nex

![Hex.pm](https://img.shields.io/hexpm/v/nex?color=informational)
![License](https://img.shields.io/github/license/lebrunel/nex?color=informational)
![Build Status](https://img.shields.io/github/actions/workflow/status/lebrunel/nex/elixir.yml?branch=main)

Nex is a powerful and flexible [Nostr](https://github.com/nostr-protocol/nostr) relay written in Elixir.

- Elixir's highly scalabe nature means Nex can easily handle a large number of concurrent connections.
- Nex features built-in IP-based rate limiting, which can be configured to suit your specific needs. 
- Run as a standalone service or plug in to an existing Plug-base or Phoenix application.

## Supported NIPs

- [x] NIP-01 - [Basic protocol flow description](https://github.com/nostr-protocol/nips/blob/master/01.md)
- [x] NIP-02 - [Contact List and Petnames](https://github.com/nostr-protocol/nips/blob/master/02.md)
- [x] NIP-04 - [Encrypted Direct Messages](https://github.com/nostr-protocol/nips/blob/master/04.md)
- [x] NIP-09 - [Event Deletion](https://github.com/nostr-protocol/nips/blob/master/09.md)
- [x] NIP-11 - [Relay Information Document](https://github.com/nostr-protocol/nips/blob/master/11.md)
- [x] NIP-12 - [Generic Tag Queries](https://github.com/nostr-protocol/nips/blob/master/12.md)
- [x] NIP-13 - [Proof of Work](https://github.com/nostr-protocol/nips/blob/master/13.md)
- [x] NIP-15 - [End of Stored Events Notice](https://github.com/nostr-protocol/nips/blob/master/15.md)
- [x] NIP-16 - [Event Treatment](https://github.com/nostr-protocol/nips/blob/master/16.md)
- [x] NIP-20 - [Command Results](https://github.com/nostr-protocol/nips/blob/master/20.md)
- [x] NIP-22 - [Event created_at Limits](https://github.com/nostr-protocol/nips/blob/master/22.md)
- [x] NIP-26 - [Delegated Event Signing](https://github.com/nostr-protocol/nips/blob/master/26.md)
- [x] NIP-28 - [Public Chat](https://github.com/nostr-protocol/nips/blob/master/28.md)
- [x] NIP-33 - [Parameterized Replaceable Events](https://github.com/nostr-protocol/nips/blob/master/33.md)
- [x] NIP-40 - [Expiration Timestamp](https://github.com/nostr-protocol/nips/blob/master/40.md)

## Quickstart

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template/Fxl2iH?referralCode=_w8n1n)

## Installation

TODO

## Deploying with Docker

TODO

## License

Nex is open source and released under the [Apache-2 License](https://github.com/lebrunel/nex/blob/master/LICENSE).

© Copyright 2023 lebrunel.
