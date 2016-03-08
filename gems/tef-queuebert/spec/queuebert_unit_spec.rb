require 'spec_helper'


describe 'Queuebert, Unit' do

  let(:clazz) { TEF::Queuebert::Queuebert }
  let(:configuration) { {} }

  it_should_behave_like 'a loosely configured component'
  it_should_behave_like 'a service component, unit level'
  it_should_behave_like 'a receiving component, unit level', [:in_queue]
  it_should_behave_like 'a sending component, unit level', [:manager_queue, :keeper_queue]
  it_should_behave_like 'a logged component, unit level'
  it_should_behave_like 'a wrapper component, unit level', [:in_queue, :output_exchange]


  # todo - make these default value tests part of a common spec

  it 'has a default suite request queue' do
    configuration.delete(:in_queue)

    queuebert = clazz.new(configuration)
    expect(queuebert.instance_variable_get(:@in_queue)).to_not be_nil
  end

  it 'has a default output exchange' do
    configuration.delete(:output_exchange)

    queuebert = clazz.new(configuration)
    expect(queuebert.instance_variable_get(:@output_exchange)).to_not be_nil
  end

end
