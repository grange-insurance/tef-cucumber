require_relative 'lib/tef/cuke_keeper'


module TEF
  module CukeKeeper

    tef_env =  !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'

    tef_config =    !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'


    db_config = YAML.load(File.open("#{tef_config}/database_#{tef_env}.yml"))
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::Base.table_name_prefix = "keeper_#{tef_env}_"
    ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))


    file_data = JSON.parse(File.read('res_5d5099d9-7e9a-45b3-b3ba-27e7e7fd6be7.json'), symbolize_names: true)

    suite_guid = file_data[:suite_guid]
    suite_guid ||= '123'
    suite = Models::TestSuite.where('guid = ?', suite_guid).first

    require 'pry'; binding.pry
    if file_data[:task_data][:results].class == String
      puts "Task errored #{file_data[:task_data][:results]}"
      return true
    end

    json_results = file_data[:task_data][:results]


    [:stdout].split("\n").last

    parser = CucumberJsonParser.new(json_results)
    feat = parser.features.first
    scen = feat.scenarios.first


    db_feat = Models::Feature.where('test_suite_id =? AND name = ? AND filename =?', suite.id, feat.name, feat.path).first
    unless db_feat
      db_feat ||= Models::Feature.new
      db_feat.filename = feat.path
      db_feat.name = feat.name
      db_feat.test_suite = suite
      db_feat.save
    end


    db_scenario = Models::Scenario.new
    db_scenario.feature = db_feat
    db_scenario.name = scen.name
    db_scenario.filename = "#{db_feat.filename}:#{scen.line_no}"
    db_scenario.steps = scen.step_text
    db_scenario.status = scen.passed? ? 'pass' : 'fail'
    db_scenario.exception = scen.error_message unless scen.passed?

    #require 'pry'; binding.pry

    db_scenario.save
    #TODO: failure data




  end
end
