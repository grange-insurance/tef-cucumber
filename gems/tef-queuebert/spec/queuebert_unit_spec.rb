require 'spec_helper'


def default_options
  {}
end


describe 'Queuebert, Unit' do

  clazz = TEF::Queuebert::Queuebert


  it_should_behave_like 'a loosely configured component', clazz

  it_should_behave_like 'a service component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, unit level', clazz, default_options, [:suite_request_queue]
  it_should_behave_like 'a sending component, unit level', clazz, default_options, [:manager_queue, :keeper_queue]

  it_should_behave_like 'a logged component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end


  before(:each) do
    @options = default_options
  end

  # todo - make these default value tests part of a common spec

  it 'has a default suite request queue' do
    @options.delete(:suite_request_queue)

    queuebert = clazz.new(@options)
    expect(queuebert.instance_variable_get(:@suite_request_queue)).to_not be_nil
  end

  it 'has a default manager queue' do
    @options.delete(:manager_queue)

    queuebert = clazz.new(@options)
    expect(queuebert.instance_variable_get(:@manager_queue)).to_not be_nil
  end

  it 'has a default keeper queue' do
    @options.delete(:keeper_queue)

    queuebert = clazz.new(@options)
    expect(queuebert.instance_variable_get(:@keeper_queue)).to_not be_nil
  end

end
