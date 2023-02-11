# Nex

Nex is a performant [nostr](https://github.com/nostr-protocol/nostr) relay, written in Elixir.

- Highly scalable and concurrent backend written in Elixir.
- Built in and configurable IP-based rate limiting.
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
- [x] NIP-40 - [Expiration Timestamp](https://github.com/nostr-protocol/nips/blob/master/40.md)

## Deploying with Docker

TODO

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/nex>.

