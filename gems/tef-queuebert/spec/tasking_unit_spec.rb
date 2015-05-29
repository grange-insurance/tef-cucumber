require 'spec_helper'

describe 'Tasking, Unit' do

  nodule = TEF::Queuebert::Tasking


  before(:each) do
    @meta_data = {'meta' => 'data'}
    @tests = ['path/to/some.feature:1', 'path/to/some.feature:2', 'path/to/some.feature:3']
  end


  it 'can create tasks for tests' do
    expect(nodule).to respond_to(:create_tasks_for)
  end

  it 'needs meta data and a collection of tests from which to create tasks' do
    expect(nodule.method(:create_tasks_for).arity).to eq(2)
  end

  it 'will only accept a collection of tests' do
    expect { nodule.create_tasks_for(@meta_data, ['some test']) }.to_not raise_error
    expect { nodule.create_tasks_for(@meta_data, 'some test') }.to raise_error(ArgumentError, /can only/i)
  end

  it 'will only accept test data as a hash' do
    expect { nodule.create_tasks_for({'meta' => 'data'}, @tests) }.to_not raise_error
    expect { nodule.create_tasks_for('meta data', @tests) }.to raise_error(ArgumentError, /can only/i)
  end

  it 'task creation returns a collection tasks' do
    created_tasks = nodule.create_tasks_for(@meta_data, @tests)

    expect(created_tasks).to be_an(Array)
    expect(created_tasks).to_not be_empty
    created_tasks.each do |task|
      expect(task).to be_a(Hash)
    end
  end

  it 'handles an empty test collection just fine' do
    expect { @created_tasks = nodule.create_tasks_for(@meta_data, []) }.to_not raise_error

    expect(@created_tasks).to be_empty
  end

  it 'appends explicit tests to the appropriate cucumber options if they already exist' do
    @meta_data[:command_line_options] = {file_paths: ["some.file"]}

    task = nodule.create_tasks_for(@meta_data, @tests).first
    task_tests = task[:task_data][:cucumber_options][:file_paths]

    expect(task_tests).to eq(["some.file"] + [@tests.first])
  end

end
