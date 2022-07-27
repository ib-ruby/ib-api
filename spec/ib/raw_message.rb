# frozen_string_literal: true

require_relative '../../lib/ib/raw_message'

VALID_MESSAGE = ['137', '20220719 18:46:24 Central Standard Time'].freeze
RSpec.describe IB::RawMessageParser do
  it 'Parser Receives a full message from the TCP Socket' do
    test_message_count = 1
    full_message = "\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00"
    socket = double
    allow(socket).to receive(:recv_from).and_return(full_message, 'x')

    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)
      break if counter >= 1

      counter += 1
      break if counter >= test_message_count
    end
  end

  it 'Parser Receives a full message in two chunks from the TCP Socket' do
    test_message_count = 1
    part_a = "\x00\x00\x00,137\x002022"
    part_b = "0719 18:46:24 Central Standard Time\x00"
    socket = double
    allow(socket).to receive(:recv_from).and_return(part_a, part_b, 'x')

    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= test_message_count
    end
    # make sure the proper number of messages 
    # are processed.
    expect(counter).to eq (test_message_count)
  end

  it 'Parser Receives two full messages' do
    test_message_count = 2
    full_message_a = "\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00"
    full_message_b = "\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00"
    socket = double
    allow(socket).to receive(:recv_from).and_return(full_message_a, full_message_b, 'x')

    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= test_message_count
    end
    expect(counter).to eq (test_message_count)
  end

  it 'Parser Receives a full message and a half, the rest in chunk b ' do
    test_message_count = 2
    full_message = "\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00\x00\x00\x00,137\x002022"
    part_message = "0719 18:46:24 Central Standard Time\x00"
    socket = double
    allow(socket).to receive(:recv_from).and_return(full_message, part_message, 'x')

    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)
      break if counter >= test_message_count

      counter += 1
      break if counter >= test_message_count
    end
    expect(counter).to eq(test_message_count)
  end

  it 'Parser Receives a full message and the first byte of a second, the rest in chunk b ' do
    test_message_count = 2
    full_message = "\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00\x00"
    part_message = "\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00"
    socket = double
    allow(socket).to receive(:recv_from).and_return(full_message, part_message, 'x')

    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)
      break if counter >= test_message_count

      counter += 1
      break if counter >= test_message_count
    end
    expect(counter).to eq(test_message_count)
  end

  bad_message = "\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x01"
  it 'Parser Receives an invalid message (last byte is not \\x00)' do
    socket = double
    allow(socket).to receive(:recv_from).and_return(bad_message)

    parser = IB::RawMessageParser.new(socket)
    expect { parser.each { |msg| } }.to raise_error(StandardError, /invalid last byte/)
  end
end
