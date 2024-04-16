# frozen_string_literal: true

require 'main_helper'

RSpec.describe 'IB::OptionChain' do
  before(:all) do
    establish_connection
    IB::Connection.current.activate_plugin 'option_chain'
  end

  after(:all) do
    close_connection
  end

  context 'when contract is_a Stock' do
    let(:contract) { IB::Stock.new(symbol: 'GE') }

    it 'returns correctly ATM put options' do
      result = contract.atm_options
      expect(result.keys).to all(be_a String)
      expect(result.keys.size).to be > 1
      first_atm_expiry_date_key = result.keys.first
      first_atm_expiry_date = Date.parse(first_atm_expiry_date_key)
      expect(result[first_atm_expiry_date_key].size).to eq(1)

      first_atm_option = result[first_atm_expiry_date_key].first
      expect(first_atm_option).to be_a(IB::Option)
      expect(first_atm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       last_trading_day: first_atm_expiry_date_key,
                                                       right: 'P',
                                                       exchange: be_a(String),
                                                       local_symbol: /GE\s+#{first_atm_expiry_date.strftime('%y%m%d')}/,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })
    end

    it 'returns correctly ATM call options' do
      result = contract.atm_options(right: :call)
      expect(result.keys).to all(be_a String)
      expect(result.keys.size).to be > 1
      first_atm_expiry_date_key = result.keys.first
      first_atm_expiry_date = Date.parse(first_atm_expiry_date_key)
      expect(result[first_atm_expiry_date_key].size).to eq(1)

      first_atm_option = result[first_atm_expiry_date_key].first
      expect(first_atm_option).to be_a(IB::Option)
      expect(first_atm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       last_trading_day: first_atm_expiry_date_key,
                                                       right: 'C',
                                                       exchange: be_a(String),
                                                       local_symbol: /GE\s+#{first_atm_expiry_date.strftime('%y%m%d')}/,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })
    end

    it 'does not find ATM options for far away ref_price' do
      result = contract.atm_options(ref_price: 0.0)
      expect(result.keys).to all(be_a String)
      expect(result.keys.size).to be > 1

      first_atm_expiry_date_key = result.keys.first
      expect(result[first_atm_expiry_date_key]).to be_empty
    end

    it 'returns correctly OTM put options' do
      result = contract.otm_options
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(6) # ATM + 5 OTM
      strike_price = result.keys.first
      expect(result[strike_price].size).to be_positive

      first_otm_option = result[strike_price].first
      expect(first_otm_option).to be_a(IB::Option)
      expect(first_otm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       right: 'P',
                                                       exchange: be_a(String),
                                                       strike: strike_price.to_f,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })

      expect(first_otm_option.strike).to be > result[result.keys[1]].first.strike
    end

    it 'returns correctly OTM call options' do
      result = contract.otm_options(right: :call)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(6) # ATM + 5 OTM
      strike_price = result.keys.first
      expect(result[strike_price].size).to be_positive

      first_otm_option = result[strike_price].first
      expect(first_otm_option).to be_a(IB::Option)
      expect(first_otm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       right: 'C',
                                                       exchange: be_a(String),
                                                       strike: strike_price.to_f,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })

      expect(first_otm_option.strike).to be < result[result.keys[1]].first.strike
    end

    it 'sorts OTM options by expiry' do
      result = contract.otm_options(sort: :expiry)
      expect(result.keys).to all(be_a String)
      expect(result.keys.size).to eq(12)
      first_otm_expiry_date_key = result.keys.first
      first_otm_expiry_date = Date.parse(first_otm_expiry_date_key)
      expect(result[first_otm_expiry_date_key].size).to be_positive

      first_otm_option = result[first_otm_expiry_date_key].first
      expect(first_otm_option).to be_a(IB::Option)
      expect(first_otm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       last_trading_day: first_otm_expiry_date_key,
                                                       right: 'P',
                                                       exchange: be_a(String),
                                                       local_symbol: /GE\s+#{first_otm_expiry_date.strftime('%y%m%d')}/,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })
    end

    it 'limits OTM put options to 3' do
      result = contract.otm_options(count: 3)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(4) # ATM + 3 OTM
    end

    it 'limits OTM call options to 3' do
      result = contract.otm_options(count: 3, right: :call)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(4) # ATM + 3 OTM
    end

    it 'does not find OTM options for far away ref_price' do
      result = contract.otm_options(ref_price: 0.0)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(0)
    end

    it 'returns correctly ITM put options' do
      result = contract.itm_options
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(6) # ATM + 5 ITM
      strike_price = result.keys.first
      expect(result[strike_price].size).to be_positive

      first_itm_option = result[strike_price].first
      expect(first_itm_option).to be_a(IB::Option)
      expect(first_itm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       right: 'P',
                                                       exchange: be_a(String),
                                                       strike: strike_price.to_f,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })

      expect(first_itm_option.strike).to be < result[result.keys[1]].first.strike
    end

    it 'returns correctly ITM call options' do
      result = contract.itm_options(right: :call)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(6) # ATM + 5 ITM
      strike_price = result.keys.first
      expect(result[strike_price].size).to be_positive

      first_itm_option = result[strike_price].first
      expect(first_itm_option).to be_a(IB::Option)
      expect(first_itm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       right: 'C',
                                                       exchange: be_a(String),
                                                       strike: strike_price.to_f,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })

      expect(first_itm_option.strike).to be > result[result.keys[1]].first.strike
    end

    it 'sorts ITM options by expiry' do
      result = contract.itm_options(sort: :expiry)
      expect(result.keys).to all(be_a String)
      expect(result.keys.size).to eq(12)
      first_itm_expiry_date_key = result.keys.first
      first_itm_expiry_date = Date.parse(first_itm_expiry_date_key)
      expect(result[first_itm_expiry_date_key].size).to be_positive

      first_itm_option = result[first_itm_expiry_date_key].first
      expect(first_itm_option).to be_a(IB::Option)
      expect(first_itm_option.attributes).to include({
                                                       symbol: 'GE',
                                                       last_trading_day: first_itm_expiry_date_key,
                                                       right: 'P',
                                                       exchange: be_a(String),
                                                       local_symbol: /GE\s+#{first_itm_expiry_date.strftime('%y%m%d')}/,
                                                       trading_class: 'GE',
                                                       multiplier: 100
                                                     })
    end

    it 'limits ITM put options to 3' do
      result = contract.itm_options(count: 3)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(4) # ATM + 3 ITM
    end

    it 'limits ITM call options to 3' do
      result = contract.itm_options(count: 3, right: :call)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(4) # ATM + 3 ITM
    end

    it 'does not find ITM options for far away ref_price' do
      result = contract.itm_options(ref_price: 10_000.0)
      expect(result.keys).to all(be_a BigDecimal)
      expect(result.keys.size).to eq(0)
    end
  end
end
