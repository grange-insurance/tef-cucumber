require 'spec_helper'


describe 'Queuebert, Unit' do

  let(:clazz) { TEF::Queuebert::Queuebert }
  let(:configuration) { {} }

  it_should_behave_like 'a loosely configured component'
  it_should_behave_like 'a service component, unit level'
  it_should_behave_like 'a receiving component, unit level', [:suite_request_queue]
  it_should_behave_like 'a sending component, unit level', [:manager_queue, :keeper_queue]
  it_should_behave_like 'a logged component, unit level'
  it_should_behave_like 'a wrapper component, unit level', [:suite_request_queue, :manager_queue, :keeper_queue]


  # todo - make these default value tests part of a common spec

  it 'has a default suite request queue' do
    configuration.delete(:suite_request_queue)

    queuebert = clazz.new(configuration)
    expect(queuebert.instance_variable_get(:@suite_request_queue)).to_not be_nil
  end

  it 'has a default manager queue' do
    configuration.delete(:manager_queue)

    queuebert = clazz.new(configuration)
    expect(queuebert.instance_variable_get(:@manager_queue)).to_not be_nil
  end

  it 'has a default keeper queue' do
    configuration.delete(:keeper_queue)

    queuebert = clazz.new(configuration)
    expect(queuebert.instance_variable_get(:@keeper_queue)).to_not be_nil
  end

end
