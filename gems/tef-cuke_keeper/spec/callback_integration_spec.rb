require 'spec_helper'
require 'active_record'
require 'database_cleaner'

describe 'CukeKeeper.callback, Integration' do

  nodule = TEF::CukeKeeper

  # Specs will be dynamically created for all of these attributes
  suite_attributes = [:requested_time, :name, :complete, :finished_time, :guid]
  feature_attributes = [:name, :filename, :suite_guid]
  scenario_attributes = [:done, :end_time, :exception, :feature_id, :line_number, :name, :runtime, :status, :steps, :suite_guid, :task_guid]


  before(:all) do
    ActiveRecord::Base.time_zone_aware_attributes = true
    ActiveRecord::Base.default_timezone = :local

    db_config = YAML.load(File.open("#{tef_config}/database_#{tef_env}.yml"))
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::Base.table_name_prefix = "keeper_#{tef_env}_"
    ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))

    #todo - fix the other database cleaning setups so that they work in non dev modes as well
    DatabaseCleaner.strategy = :truncation, {only: ["keeper_#{tef_env}_scenarios", "keeper_#{tef_env}_features", "keeper_#{tef_env}_test_suites"]}
    DatabaseCleaner.start
  end

  before(:each) do
    Timecop.freeze
  end

  after(:each) do
    Timecop.return
  end

  before(:each) do
    @test_suite_creation_payload = {type: 'suite_creation', suite_guid: 'test suite foo', requested_time: DateTime.now.to_json, task_ids: ['1']}
    @test_suite_stop_payload = {type: 'suite_stop'}

    @mock_logger = create_mock_logger
  end


  before(:each) do
    Timecop.freeze
  end

  after(:each) do
    Timecop.return
  end

  after(:each) do
    DatabaseCleaner.clean
  end


  describe 'message handling' do

    it "logs when it receives a payload type that it doesn't know how to handle" do
      nodule.callback.call(create_mock_delivery_info, create_mock_properties, {type: 'foobar'}, @mock_logger)

      expect(@mock_logger).to have_received(:warn).with(/do not know.*foobar/i)
    end

    describe 'suite creation message handling' do

      let(:request_name_for) { {guid: :suite_guid,
                                name: :name,
                                requested_time: :requested_time,
                                finished_time: :finished_time} }


      it "knows how to handle payloads of type 'suite_creation'" do
        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, @mock_logger)

        expect(@mock_logger).to_not have_received(:warn)
      end

      it 'logs when it receives a creation request that does not include a collection of task ids' do
        @test_suite_creation_payload.delete(:task_ids)

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, @mock_logger)

        expect(@mock_logger).to have_received(:warn).with(/no task ids/i)
      end

      it 'logs when it receives a creation request whose collection of task ids is empty' do
        @test_suite_creation_payload[:task_ids] = []

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, @mock_logger)

        expect(@mock_logger).to have_received(:warn).with(/no task ids/i)
      end

      context "when it's a new suite" do

        it 'creates a record for the created suite' do
          @test_suite_creation_payload[:suite_guid] = 'new test suite guid'

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

          expect(TEF::CukeKeeper::Models::TestSuite.find_by(guid: 'new test suite guid')).to_not be_nil
        end

        suite_attributes.each do |attribute|

          # Completion gets determined elsewhere
          unless attribute == :complete
            it "stores the '#{attribute}' when it creates a suite record" do
              values = {name: 'bar',
                        requested_time: (Time.now.getlocal + 7).to_s,
                        suite_guid: 'test suite 54321'
              }

              request_attribute = request_name_for[attribute]

              @test_suite_creation_payload[request_attribute] = values[request_attribute]
              nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)


              if attribute == :requested_time
                expect(TEF::CukeKeeper::Models::TestSuite.first.send(attribute).to_i).to eq(DateTime.parse(values[attribute]).to_i)
              else
                expect(TEF::CukeKeeper::Models::TestSuite.first.send(attribute)).to eq(values[request_attribute])
              end
            end
          end
        end

        it "defaults to 'now' if no request time is provided when it creates a suite record" do
          test_time = DateTime.now.to_json
          @test_suite_creation_payload.delete(:requested_time)

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

          expect(TEF::CukeKeeper::Models::TestSuite.first.requested_time.to_i).to eq(DateTime.parse(test_time).to_i)
        end

        it "defaults to 'incomplete' if no completion value is provided when it creates a suite record" do
          @test_suite_creation_payload.delete(:complete)

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

          expect(TEF::CukeKeeper::Models::TestSuite.first.complete).to eq(false)
        end

      end

      context "when it's an existing suite" do

        it 'logs a warning if a record already exists for the created suite' do
          suite_guid = 'existing test suite guid'

          suite = TEF::CukeKeeper::Models::TestSuite.new(guid: suite_guid, requested_time: DateTime.now)
          suite.save

          @test_suite_creation_payload[:suite_guid] = suite_guid

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, @mock_logger)

          expect(@mock_logger).to have_received(:warn).with(/#{suite_guid}.*already.*created/)
        end

        it 'does not create a new record if a record already exists for the created suite' do
          suite_guid = 'existing test suite guid'
          suite = TEF::CukeKeeper::Models::TestSuite.new(guid: suite_guid, requested_time: DateTime.now)
          suite.save


          expect(TEF::CukeKeeper::Models::TestSuite.where(guid: suite_guid).count).to eq(1)

          @test_suite_creation_payload[:suite_guid] = suite_guid
          nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)


          expect(TEF::CukeKeeper::Models::TestSuite.where(guid: suite_guid).count).to eq(1)
        end

        suite_attributes.each do |attribute|

          # Completion gets determined elsewhere and if the guid is different then you aren't updating the same suite anyway
          unless [:complete, :guid].include?(attribute)
            it "updates the existing record with the new '#{attribute}' if a record already exists for the created suite" do
              values = {owner: {old: 'foo', new: 'bar'},
                        name: {old: 'foo', new: 'bar'},
                        env: {old: 'foo', new: 'bar'},
                        requested_time: {old: DateTime.now, new: (Time.now.getlocal + 7).to_s},
                        finished_time: {old: DateTime.now, new: (Time.now.getlocal + 7).to_s}
              }[attribute]

              suite_guid = 'existing test suite guid'
              suite = TEF::CukeKeeper::Models::TestSuite.new(guid: suite_guid, requested_time: DateTime.now, attribute => values[:old])
              suite.save


              @test_suite_creation_payload[:suite_guid] = suite_guid
              @test_suite_creation_payload[attribute] = values[:new]
              nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)


              if [:requested_time, :finished_time].include?(attribute)
                expect(TEF::CukeKeeper::Models::TestSuite.find_by(guid: suite_guid).send(attribute).to_i).to eq(DateTime.parse(values[:new]).to_i)
              else
                expect(TEF::CukeKeeper::Models::TestSuite.find_by(guid: suite_guid).send(attribute)).to eq(values[:new])
              end
            end

            it "does not update the existing '#{attribute}' of the record if new data for that part is not provided" do
              old_data = {name: 'foo', requested_time: DateTime.now}
              new_data = {name: 'bar', requested_time: (DateTime.now + 7).to_json}

              suite_guid = 'existing test suite guid'
              suite = TEF::CukeKeeper::Models::TestSuite.new(old_data.merge(guid: suite_guid))
              suite.save


              new_data.delete(attribute)
              @test_suite_creation_payload[:suite_guid] = suite_guid
              @test_suite_creation_payload.merge!(new_data)
              nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)


              if attribute == :requested_time
                expect(TEF::CukeKeeper::Models::TestSuite.find_by(guid: suite_guid).send(attribute).to_i).to eq(old_data[attribute].to_i)
              else
                expect(TEF::CukeKeeper::Models::TestSuite.find_by(guid: suite_guid).send(attribute)).to eq(old_data[attribute])
              end
            end
          end
        end

      end

      it 'creates placeholder records for each task in the suite' do
        @test_suite_creation_payload[:task_ids] = ['foo', 'bar']


        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: 'foo')).to be_nil
        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: 'bar')).to be_nil

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)


        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: 'foo')).to_not be_nil
        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: 'bar')).to_not be_nil
      end

      it "placeholder task records default to 'incomplete' when it created" do
        @test_suite_creation_payload[:task_ids] = ['foo']

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: 'foo').done).to eq(false)
      end

      it 'does not create a placeholder record if a record already exists for the created task' do
        task_guid = 'bar'
        task = TEF::CukeKeeper::Models::Scenario.new(suite_guid: 'foo', task_guid: task_guid)
        task.save


        expect(TEF::CukeKeeper::Models::Scenario.where(task_guid: task_guid).count).to eq(1)

        @test_suite_creation_payload[:task_ids] = [task_guid]
        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)


        expect(TEF::CukeKeeper::Models::Scenario.where(task_guid: task_guid).count).to eq(1)
      end

      it 'associates existing task records with the created suite if their task ids are included in the request' do
        TEF::CukeKeeper::Models::Scenario.new(suite_guid: 'test suite x', task_guid: '1').save
        TEF::CukeKeeper::Models::Scenario.new(suite_guid: 'test suite x', task_guid: '2').save
        TEF::CukeKeeper::Models::Scenario.new(suite_guid: 'test suite x', task_guid: '3').save

        @test_suite_creation_payload[:suite_guid] = 'test suite foo'
        @test_suite_creation_payload[:task_ids] = ['1', '3']
        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: '1').suite_guid).to eq('test suite foo')
        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: '2').suite_guid).to_not eq('test suite foo')
        expect(TEF::CukeKeeper::Models::Scenario.find_by(task_guid: '3').suite_guid).to eq('test suite foo')
      end

      it 'checks to see if the suite is completed when it is created (complete)' do
        # No tasks at all is a quick way for it to be finished already
        @test_suite_creation_payload[:task_ids] = []
        @test_suite_creation_payload[:complete] = false

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

        expect(TEF::CukeKeeper::Models::TestSuite.first.complete).to eq(true)
      end

      it 'checks to see if the suite is completed when it is created (incomplete)' do
        # No tasks at all is a quick way for it to be finished already
        @test_suite_creation_payload[:task_ids] = ['foo']
        @test_suite_creation_payload[:complete] = true

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

        expect(TEF::CukeKeeper::Models::TestSuite.first.complete).to eq(false)
      end

      it 'stores the completion time when the suite is complete' do
        # No tasks at all is a quick way for it to be finished already
        @test_suite_creation_payload[:task_ids] = []

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, create_mock_logger)

        expect(TEF::CukeKeeper::Models::TestSuite.first.finished_time.to_i).to eq(DateTime.now.to_i)
      end

    end

    describe 'suite stop message handling' do

      it "knows how to handle payloads of type 'suite_stop'" do
        # Need a suite to stop so that a warning is not raised
        TEF::CukeKeeper::Models::TestSuite.new(guid: 'foo', requested_time: DateTime.now).save

        @test_suite_stop_payload[:suite_guid] = 'foo'
        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_stop_payload, @mock_logger)

        expect(@mock_logger).to_not have_received(:warn)
      end

      it 'stores the stopping time when the suite is stopped' do
        suite = TEF::CukeKeeper::Models::TestSuite.new(guid: 'suite foo', requested_time: DateTime.now)
        suite.save

        @test_suite_stop_payload[:suite_guid] = 'suite foo'
        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_stop_payload, @mock_logger)

        expect(TEF::CukeKeeper::Models::TestSuite.first.finished_time.to_i).to eq(DateTime.now.to_i)
      end

      it "does not mark the suite as complete when stopped unless all of the suite's tasks have been finished" do
        TEF::CukeKeeper::Models::Scenario.new(suite_guid: 'suite foo', task_guid: '1', done: false).save
        suite = TEF::CukeKeeper::Models::TestSuite.new(guid: 'suite foo', requested_time: DateTime.now)
        suite.save

        @test_suite_stop_payload[:suite_guid] = 'suite foo'
        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_stop_payload, @mock_logger)
        expect(TEF::CukeKeeper::Models::TestSuite.first.complete).to be false


        TEF::CukeKeeper::Models::Scenario.find_by(task_guid: '1').update(done: true)

        @test_suite_stop_payload[:suite_guid] = 'suite foo'
        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_stop_payload, @mock_logger)
        expect(TEF::CukeKeeper::Models::TestSuite.first.complete).to be true
      end

      it 'logs a warning if no record exists for the stopped suite' do
        guid = 'foo'
        @test_suite_stop_payload[:suite_guid] = guid

        nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_stop_payload, @mock_logger)

        expect(@mock_logger).to have_received(:warn).with(/no.*#{guid}.*stop/i)
      end

    end

    describe 'suite update message handling' do

      it 'should do something' do
        skip('Finish me')
      end

    end


    describe 'task message handling' do


      let(:example_test_output) { generic_test_output }
      let(:generic_test_result_message) { {:type => 'task', :task_data => {:results => {:stdout => example_test_output}}, guid: 'task_112233'} }


      feature_attributes.each do |attribute|
        it "#{attribute} still needs to be tested" do
          skip('Finish me')
        end
      end


      [:scenario, :outline].each do |result_type|
        scenario_attributes.each do |attribute|

          # Done-ness, end time, and the feature id that the scenario is attached to are derived, not provided
          unless [:done, :end_time, :feature_id].include?(attribute)
            it "stores the '#{attribute}' when it saves a #{result_type} result" do
              values = {name: 'foo',
                        exception: 'Bad things happened!',
                        line_number: 7,
                        runtime: 5.0,
                        status: 'pending',
                        suite_guid: 'suite999',
                        task_guid: 'test_task_123',
                        steps: "* some step\nAnd another step"
              }
              update_test_output(result_type, generic_test_result_message, attribute, values[attribute])

              nodule.callback.call(create_mock_delivery_info, create_mock_properties, generic_test_result_message, create_mock_logger)

              expect(TEF::CukeKeeper::Models::Scenario.first.send(attribute)).to eq(values[attribute])
            end
          end

          it "updates the existing record with the new '#{attribute}' if a record already exists for the #{result_type}" do
            skip('finish me')
          end

        end

        it "stores the end time when the #{result_type} task is stored" do
          nodule.callback.call(create_mock_delivery_info, create_mock_properties, generic_test_result_message, create_mock_logger)

          expect(TEF::CukeKeeper::Models::Scenario.first.end_time.to_i).to eq(DateTime.now.to_i)
        end

        it "marks the task as done when the #{result_type} task is stored" do
          nodule.callback.call(create_mock_delivery_info, create_mock_properties, generic_test_result_message, create_mock_logger)

          expect(TEF::CukeKeeper::Models::Scenario.first.done).to be true
        end

        it "feature_id still needs to be tested for #{result_type}" do
          skip('Finish me')
        end
      end

      context 'when the task is part of a suite' do

        let(:suite_test_result_message) { generic_test_result_message.merge(suite_guid: 'a_test_suite_guid') }

        context "when the task's suite record doesn't exist yet" do

          before(:each) do
            TEF::CukeKeeper::Models::TestSuite.delete_all
          end

          it "creates a record for the task's suite" do
            suite_test_result_message[:suite_guid] = 'new test suite guid'

            nodule.callback.call(create_mock_delivery_info, create_mock_properties, suite_test_result_message, create_mock_logger)

            expect(TEF::CukeKeeper::Models::TestSuite.find_by(guid: 'new test suite guid')).to_not be_nil
          end

        end

      end

      [:scenario, :outline].each do |result_type|

        it "considers a #{result_type} passing if all steps pass" do
          update_test_output(result_type, generic_test_result_message, :status, 'passing')

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, generic_test_result_message, create_mock_logger)

          expect(TEF::CukeKeeper::Models::Scenario.first.status).to eq('pass')
        end

        it "considers a #{result_type} failing if any step fails" do
          update_test_output(result_type, generic_test_result_message, :status, 'failing')

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, generic_test_result_message, create_mock_logger)

          expect(TEF::CukeKeeper::Models::Scenario.first.status).to eq('fail')
        end

        it "considers a #{result_type} pending if there is a pending step" do
          update_test_output(result_type, generic_test_result_message, :status, 'pending')

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, generic_test_result_message, create_mock_logger)

          expect(TEF::CukeKeeper::Models::Scenario.first.status).to eq('pending')
        end

        it "considers a #{result_type} undefined if there is an undefined step step" do
          update_test_output(result_type, generic_test_result_message, :status, 'undefined')

          nodule.callback.call(create_mock_delivery_info, create_mock_properties, generic_test_result_message, create_mock_logger)

          expect(TEF::CukeKeeper::Models::Scenario.first.status).to eq('undefined')
        end
      end

    end


    it 'logs when a suite has been completed' do
      # No tasks at all is a quick way for it to be finished already
      @test_suite_creation_payload[:task_ids] = []
      suite_guid = 'suite foo'
      @test_suite_creation_payload[:suite_guid] = suite_guid

      nodule.callback.call(create_mock_delivery_info, create_mock_properties, @test_suite_creation_payload, @mock_logger)

      expect(@mock_logger).to have_received(:info).with(/suite.*#{suite_guid}.*finished.*#{Regexp.escape(DateTime.now.to_s)}/i)
    end

  end

end
