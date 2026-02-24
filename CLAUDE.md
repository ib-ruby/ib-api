# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ib-api** is a Ruby gem providing a modular interface to Interactive Brokers' TWS API (Trader Workstation/Gateway). It's a modern reimplementation of ib-ruby designed for TWS version 10.19+ with Zeitwerk integration and an extensible plugin system.

## Architecture

The codebase follows an **event-driven, message-based architecture** with three main layers:

1. **Connection Layer** (`lib/ib/connection.rb`): Manages TCP socket connection to TWS/Gateway, handles message queuing, and provides the primary API interface. Uses a workflow state machine (virgin → ready/gateway_mode/lean_mode → account_based_operations).

2. **Message Layer** (`lib/ib/messages/`): Bidirectional message system using a `def_message` macro to dynamically generate message classes. Supports multiple IB API versions (currently client version 66, server version 165+). Messages are processed by `RawMessageParser` which decodes the binary protocol from IB.

3. **Model Layer** (`models/ib/`, Zeitwerk-loaded): ActiveModel-based data models for contracts (Stock, Option, Future, etc.), orders, market data, and spreads.

**Plugin Architecture**: Extensible system in `plugins/ib/` that adds automation capabilities. Plugins extend `IB::Connection` through mixins and are activated via `activate_plugin`. State machine manages plugin availability based on connection state.

## Development Commands

### Testing
```bash
# Run all tests
bundle exec rake spec
# or
bundle exec rspec

# Run with Guard (continuous testing)
bundle exec guard

# Run specific test file
bundle exec rspec spec/ib/contract_spec.rb

# Run focused tests (using fit/fdescribe/fcontext or :focus tag)
bundle exec rspec --tag focus
```

### Interactive Console
```bash
# Connect to IB Gateway (default)
./console g

# Connect to TWS
./console t

# The console sets up C as the connection instance
# C points to IB::Connection.current
```

### Build
```bash
# Install dependencies
bundle install

# Build the gem
gem build ib-api.gemspec
```

## Testing Configuration

Tests require `spec/spec.yml` with IB account details:
```yaml
:connection:
  :port: 4002           # IB Gateway port (4001/4002) or TWS (7496/7497)
  :host: 127.0.0.1      # IB server host
  :account: DU123456    # Your paper account ID (required)
  :base_currency: EUR   # Base currency
  :market_data: false  # Include market-data dependent tests
:stock:
  :symbol: 'GE'         # Sample symbol for tests
```

The test suite is safe to run with a real (paper trading) account as integration tests on order placement are not included.

## Key Patterns

### Message Processing
- Incoming messages are queued in `IB::Connection#received` hash by message type
- Subscribe to messages: `ib.subscribe(:OrderStatus) { |msg| ... }`
- Wait for messages: `ib.wait_for :OrderStatus`
- Send messages: `ib.send_message :PlaceOrder, order: order, contract: contract`

### Connection Workflow
States: `virgin` → `lean_mode`/`gateway_mode`/`ready` → `account_based_operations` → `account_based_orderflow`

- `lean_mode`: Minimal connection, no account data
- `gateway_mode`: Multi-account gateway access
- `ready`: Standard single-account connection
- `account_based_operations`: Account data loaded, portfolio available
- `account_based_orderflow`: Order processing active

### Plugin Development
Plugins are Ruby files in `plugins/ib/` that extend `IB::Connection`:
```ruby
# plugins/ib/my_plugin.rb
module IB
  module Connection
    def my_method
      # implementation
    end
  end
end
```

Activate: `ib.activate_plugin :my_plugin`

### Zeitwerk Autoloading
Models in `models/ib/` are autoloaded by Zeitwerk. No explicit requires needed. Inflection rules are set in `lib/ib-api.rb`.

## Testing Framework

- **RSpec** with: `rspec-its`, `rspec-given`, `rspec-collection_matchers`
- Test data: `SAMPLE` constant holds a test IB::Stock configured from `spec.yml`
- Account shortcut: `ACCOUNT` constant holds the account ID from `spec.yml`
- Focus tests: Use `fit`, `fdescribe`, `fcontext` or tag with `:focus`

## Message Debugging

When implementing new message types, uncomment line 37 in `lib/ib/messages/incoming/abstract_message.rb` to see raw TWS output. The console (`./console`) is useful for quick message testing - inspect `C.received` hash to see collected messages.

## Important Files

- `lib/ib/connection.rb`: Main connection and workflow management
- `lib/ib/plugins.rb`: Plugin activation system
- `lib/ib-api.rb`: Entry point, Zeitwerk setup
- `lib/ib/messages/outgoing/` & `lib/ib/messages/incoming/`: Message definitions
- `models/ib/`: Data models (Contract, Order, etc.)
- `spec/spec_helper.rb`: Test configuration
- `spec/howto.md`: Guide for implementing and testing messages
