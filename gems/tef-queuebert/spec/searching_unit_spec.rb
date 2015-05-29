require 'spec_helper'

describe 'Searching, Unit' do

  nodule = TEF::Queuebert::Searching


  it 'can find test cases' do
    expect(nodule).to respond_to(:find_test_cases)
  end

  it 'needs a place to look, one or more directories to search, and optional filters' do
    expect(nodule.method(:find_test_cases).arity).to eq(-3)
  end

  it 'knows what search filters are available for use' do
    expect(nodule).to respond_to(:known_filters)
  end

  it 'tracks its filters as an array of symbols' do
    filters = nodule.known_filters

    expect(filters).to be_an(Array)
    expect(filters).to_not be_empty

    filters.each do |filter|
      expect(filter).to be_a(Symbol)
    end
  end

end
