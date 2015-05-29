require 'spec_helper'


describe 'CukeKeeper.callback, Unit' do

  nodule = TEF::CukeKeeper


  it 'provides a callback' do
    expect(nodule).to respond_to(:callback)
  end

  it 'has a Proc for its callback' do
    expect(nodule.callback).to be_a_kind_of(Proc)
  end

  it 'can handle delivery information, properties, a payload, and a logger as arguments' do
    expect(nodule.callback.arity).to eq(4)
  end

end
