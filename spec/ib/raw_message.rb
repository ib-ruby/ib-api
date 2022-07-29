# frozen_string_literal: true

require_relative '../../lib/ib/raw_message'

# recvfrom return a message in first record of
# array.
def array_msg(msg)
  [msg,nil]
end

# Each test shouldn't get to this message.
BAD_MSG = array_msg('x').freeze

VALID_MESSAGE = ['137', '20220719 18:46:24 Central Standard Time'].freeze
MAX_ITERATIONS = 50
RSpec.describe IB::RawMessageParser do
  it 'Parser Receives a full message from the TCP Socket' do
    full_message = array_msg("\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00")
    socket = double
    allow(socket).to receive(:recvfrom).and_return(full_message, BAD_MSG)

    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq (1)
  end

  it 'Parser Receives a full message in two chunks from the TCP Socket' do
    part_a = array_msg("\x00\x00\x00,137\x002022")
    part_b = array_msg("0719 18:46:24 Central Standard Time\x00")
    socket = double
    allow(socket).to receive(:recvfrom).and_return(part_a, part_b, BAD_MSG)

    parser = IB::RawMessageParser.new(socket)

    #shouldn't return a message
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(0)

    #should return a message
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(1)
  end

  it 'Parser Receives two full messages' do
    full_message_a = array_msg("\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00")
    full_message_b = array_msg("\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00")
    socket = double
    allow(socket).to receive(:recvfrom).and_return(full_message_a, full_message_b, BAD_MSG)

    #should return a message
    counter = 0
    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(1)

    #should return a message
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(1)

  end

  it 'Parser Receives two full messages in one recvfrom call' do
    message = "\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00"
    two_messages = array_msg(message+message)
    socket = double
    allow(socket).to receive(:recvfrom).and_return(two_messages, BAD_MSG)

    #should return a message
    counter = 0
    parser = IB::RawMessageParser.new(socket)
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 2
    end
    expect(counter).to eq(2)

  end

  it 'Parser Receives a full message and a half, the rest in chunk b ' do
    full_message = array_msg("\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00\x00\x00\x00,137\x002022")
    part_message = array_msg("0719 18:46:24 Central Standard Time\x00")
    socket = double
    allow(socket).to receive(:recvfrom).and_return(full_message, part_message, BAD_MSG)

    parser = IB::RawMessageParser.new(socket)

    #should return a message
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(1)

    #should return a message
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(1)
  end

  it 'Parser Receives a full message and the first byte of a second, the rest in chunk b ' do
    full_message = array_msg("\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00\x00")
    part_message = array_msg("\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x00")
    socket = double
    allow(socket).to receive(:recvfrom).and_return(full_message, part_message, BAD_MSG)

    parser = IB::RawMessageParser.new(socket)

    #should return a message
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(1)


    #should return a message
    counter = 0
    parser.each do |message|
      expect(message).to eq(VALID_MESSAGE)

      counter += 1
      break if counter >= 1
    end
    expect(counter).to eq(1)
  end

  bad_message = array_msg("\x00\x00\x00,137\x0020220719 18:46:24 Central Standard Time\x01")
  it 'Parser Receives an invalid message (last byte is not \\x00)' do
    socket = double
    allow(socket).to receive(:recvfrom).and_return(bad_message)

    parser = IB::RawMessageParser.new(socket)
    expect { parser.each { |msg| } }.to raise_error(StandardError, /invalid last byte/)
  end
end
