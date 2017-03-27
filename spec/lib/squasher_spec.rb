require 'spec_helper'

describe Squasher do
  context '.squash' do
    specify { expected_covert("2013/12/23", Time.new(2013, 12, 23)) }
    specify { expected_covert("2013", Time.new(2013, 1, 1)) }

    def expected_covert(input, expected)
      expect(Squasher::Worker).to receive(:process).with(expected)
      Squasher.squash(input, [])
    end
  end
end
