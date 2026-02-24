# LLM Guide for ib-api

**Purpose**: This guide is optimized for LLMs (Large Language Models) to understand and work with the ib-api codebase efficiently.

---

## QUICK MENTAL MODEL

**What is this?**: A Ruby gem that provides a programmatic interface to Interactive Brokers' trading platform (TWS/Gateway).

**Core pattern**: You create a `Connection` object → it opens a TCP socket to IB → you send/recv messages → events trigger callbacks → data flows through plugins.

**Key insight**: Everything is message-driven. Connection manages a state machine, plugins extend functionality, and models represent trading objects.

---

## FILE MAP (WHERE THINGS LIVE)

```
lib/ib/
├── connection.rb          # CORE: Main Connection class, workflow state machine
├── plugins.rb             # Plugin activation system
├── messages/
│   ├── outgoing/          # Messages sent TO IB (requests)
│   └── incoming/          # Messages received FROM IB (responses)
└── constants.rb           # IB API enums/constants

models/ib/                  # Zeiteerk-loaded models
├── contract.rb            # Base class for all instruments
├── stock.rb, option.rb, future.rb, etc.  # Specific contract types
├── order.rb               # Order objects
└── bar.rb                 # OHLCV market data

plugins/ib/                 # Plugin implementations (extend Connection)
├── verify.rb              # Contract verification
├── market-price.rb        # Current price fetching
├── managed-accounts.rb    # Account/portfolio management
└── ...

spec/
├── spec_helper.rb         # Test config, loads spec.yml
├── spec.yml               # IB connection settings (REQUIRED for tests)
└── howto.md               # Guide for implementing new messages
```

---

## THE CONNECTION OBJECT (CENTRAL HUB)

```ruby
require 'ib-api'

# Create connection (does NOT connect yet)
ib = IB::Connection.new(host: '127.0.0.1', port: 7497)

# Connect (triggers workflow state transition)
ib.try_connection!  # or use the event: ib.try_connection

# The connection is globally accessible
IB::Connection.current == ib  # => true
```

**Connection attributes**:
- `socket`: TCP connection to IB
- `next_local_id`: Next available order ID
- `received`: Hash of received messages (by type)
- `plugins`: Array of activated plugin names
- `workflow_state`: Current state (virgin, ready, gateway_mode, etc.)

---

## WORKFLOW STATE MACHINE

**States (linear progression typical)**:

```
virgin (initial)
    │
    ├─→ try_connection! → ready
    │
    ├─→ activate_managed_accounts! → gateway_mode
    │
    └─→ collect_data! → lean_mode

ready
    │
    ├─→ initialize_managed_accounts! → account_based_operations
    │
    └─→ disconnect! → disconnected

account_based_operations
    │
    └─→ initialize_order_handling! → account_based_orderflow
```

**State meanings**:
- `virgin`: No connection
- `ready`: Connected, basic functionality
- `gateway_mode`: Multi-account gateway access
- `lean_mode`: Minimal data collection
- `account_based_operations`: Account/portfolio data loaded
- `account_based_orderflow`: Order processing active

---

## MESSAGE SYSTEM (THE PROTOCOL)

**Sending messages**:
```ruby
# Method 1: Send symbol
ib.send_message :PlaceOrder, order: my_order, contract: my_contract

# Method 2: Send class
ib.send_message IB::Messages::Outgoing::PlaceOrder, order: my_order, contract: my_contract

# Method 3: Use instance
msg = IB::Messages::Outgoing::PlaceOrder.new(order: my_order, contract: my_contract)
ib.send_message msg
```

**Receiving messages** (subscribe to events):
```ruby
# Subscribe to a message type
subscription_id = ib.subscribe(:OrderStatus) do |msg|
  puts "Order #{msg.order_id}: #{msg.status}"
end

# Wait for a specific message type
ib.wait_for :OrderStatus, timeout: 5

# Access received messages
ib.received[:OrderStatus].each { |msg| ... }
```

**Message structure**:
- Outgoing messages: defined in `lib/ib/messages/outgoing/`
- Incoming messages: defined in `lib/ib/messages/incoming/`
- Messages use `def_message` macro to generate classes
- Each message has an ID and version for protocol compatibility

---

## PLUGIN SYSTEM (EXTENSIBILITY)

**What plugins do**: Extend `IB::Connection` with additional methods by reopening the module.

**How to use**:
```ruby
# Activate plugin(s)
ib.activate_plugin :verify, :market_price, :connection_tools

# Now methods from those plugins are available
contract = IB::Stock.new(symbol: 'GE')
verified = contract.verify  # provided by :verify plugin
price = contract.market_price  # provided by :market_price plugin
```

**How plugins are written**:
```ruby
# plugins/ib/my_plugin.rb
module IB
  module Connection
    def my_custom_method
      # Can access @socket, send_message, etc.
      send_message :SomeRequest
    end
  end
end
```

**Common plugins**:
- `connection-tools`: Ensures active connection
- `verify`: Fetch contract details from TWS
- `managed-accounts`: Fetch account/portfolio data
- `market-price`: Get current market price
- `advanced-account`: Account-based trading operations
- `greeks`: Option risk calculations
- `option-chain`: Build option chains

---

## MODELS (DATA STRUCTURES)

**Contracts** (base: `IB::Contract`):
```ruby
stock = IB::Stock.new(symbol: 'GE', exchange: 'SMART', currency: 'USD')
option = IB::Option.new(symbol: 'GE', strike: 50, right: 'CALL', expiry: '20240120')
future = IB::Future.new(symbol: 'ES', expiry: '202403')
```

**Orders**:
```ruby
order = IB::Order.new(
  total_quantity: 100,
  action: :buy,
  order_type: 'LMT',
  limit_price: 35.0
)

# Place order
local_id = ib.place_order(order, stock)
```

**Order methods on Connection**:
- `place_order(order, contract)`: Place new order
- `modify_order(order, contract)`: Modify existing order
- `cancel_order(*local_ids)`: Cancel order(s)

---

## TESTING PATTERNS

**Test setup**:
```ruby
# spec/spec_helper.rb loads:
require 'spec_helper'

# Constants available:
OPTS[:connection]  # Hash from spec.yml
ACCOUNT            # Account ID from spec.yml
SAMPLE             # IB::Stock from spec.yml

# Example test:
describe IB::Stock do
  subject { IB::Stock.new(symbol: 'GE') }

  it "verifies contract" do
    verified = subject.verify
    expect(verified).to be_truthy
  end
end
```

**Running tests**:
```bash
# All tests
bundle exec rspec

# Single file
bundle exec rspec spec/ib/contract_spec.rb

# Focused (only tests with :focus tag or fit/fdescribe)
bundle exec rspec --tag focus
```

**IMPORTANT**: Tests require valid IB credentials in `spec/spec.yml`:
```yaml
:connection:
  :port: 4002
  :host: 127.0.0.1
  :account: DU123456  # Your paper account ID
```

---

## CONSOLE USAGE

```bash
# Start console (connects to Gateway by default)
./console g    # or ./console t for TWS

# In console:
C               # => IB::Connection.current instance
C.received     # => Hash of received messages
C.plugins      # => Array of active plugins

# Example session:
> contract = IB::Stock.new(symbol: 'GE')
> contract.verify
> contract.market_price
```

---

## CODE PATTERNS TO RECOGNIZE

**1. Event subscription pattern**:
```ruby
ib.subscribe(:MessageName) { |msg| ... }
```

**2. Wait for response pattern**:
```ruby
ib.send_message :Request
ib.wait_for :Response
```

**3. Plugin activation pattern**:
```ruby
ib.activate_plugin :plugin_name
```

**4. Connection state transitions**:
```ruby
ib.try_connection!        # Connect
ib.initialize_managed_accounts!  # Load account data
```

**5. Order placement**:
```ruby
local_id = ib.place_order(order, contract)
ib.wait_for :OpenOrder
```

---

## COMMON OPERATIONS

**Get contract details**:
```ruby
ib.activate_plugin :verify
contract = IB::Stock.new(symbol: 'GE')
details = contract.verify  # Returns array of Contract objects
```

**Get current price**:
```ruby
ib.activate_plugin :market_price
contract = IB::Stock.new(symbol: 'GE')
price = contract.market_price
```

**Place order**:
```ruby
contract = IB::Stock.new(symbol: 'GE')
order = IB::Order.new(limit_price: 35.0, order_type: 'LMT', total_quantity: 100, action: :buy)
ib.place_order(order, contract)
```

**Get account/portfolio data**:
```ruby
ib.activate_plugin :managed_accounts
ib.get_account_data
ib.portfolio_values  # Hash of portfolio positions
```

---

## DEBUGGING NEW MESSAGES

When implementing a new message type:

1. Uncomment line 37 in `lib/ib/messages/incoming/abstract_message.rb` to see raw TWS output
2. Use the console (`./console`) to test
3. Send the request and inspect `C.received[:MessageName]`
4. Check the buffer attribute for unparsed data

---

## KEY DEPENDENCIES

- **Zeitwerk**: Modern Ruby autoloading (models in `models/ib/` are autoloaded)
- **ActiveModel**: Base for data models
- **Workflow**: State machine for Connection
- **RSpec**: Testing framework
- **Ox**: XML parsing for some messages

---

## API VERSIONS

- Client version: 66 (API 9.71+)
- Server version: 165+ (TWS 10.19+)
- Protocol supports multiple IB API versions via message versioning

---

## MENTAL CHECKLIST FOR TASKS

**Before modifying**:
1. Read the relevant model or message definition first
2. Check if a plugin already provides the functionality
3. Understand the current workflow state

**When adding new messages**:
1. Define in `lib/ib/messages/outgoing/` (request) or `incoming/` (response)
2. Use `def_message` macro with proper ID and version
3. Test in console first, then write spec

**When adding plugins**:
1. Create file in `plugins/ib/`
2. Reopen `IB::Connection` module
3. Activate via `ib.activate_plugin :plugin_name`

**When writing tests**:
1. Ensure `spec/spec.yml` has valid credentials
2. Use `SAMPLE` constant for test data
3. Use `ib.wait_for` to wait for async responses
