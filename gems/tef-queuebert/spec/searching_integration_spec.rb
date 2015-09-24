require 'spec_helper'


describe 'Searching, Integration' do

  nodule = TEF::Queuebert::Searching


  before(:each) do
    @test_file = "#{@default_file_directory}/a_test.feature"
    file_text = "Feature: Test feature

                   @tag
                   Scenario: Test scenario
                     * some step"

    File.open(@test_file, 'w') { |file| file.write(file_text) }

    @root = @default_file_directory
    @target = '.'
  end


  it 'searching returns a collection of test cases' do
    search_output = nodule.find_test_cases(@root, @target)

    expect(search_output).to be_an(Array)
    expect(search_output).to_not be_empty
    search_output.each do |test_case|
      expect(test_case).to match(/^.+:\d+$/)
    end
  end

  it 'can search without being provided filters' do
    expect { nodule.find_test_cases(@root, @target) }.to_not raise_error
  end

  it 'will only accept strings, regular expressions, arrays, or collections thereof as tag filters' do
    filters = nodule.known_filters.select { |filter| filter.to_s =~ /tag/ }

    filters.each do |filter|
      expect { nodule.find_test_cases(@root, @target, filter => '@some_value') }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => /some_pattern/) }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => ['@some_value', /some_pattern/]) }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => ['@some_value', [/nested_pattern/]]) }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => ['@some_value', [/nested_pattern/, :bad_value]]) }.to raise_error(ArgumentError, /must be a/i)
      expect { nodule.find_test_cases(@root, @target, filter => :something_else) }.to raise_error(ArgumentError, /must be a/i)
      expect { nodule.find_test_cases(@root, @target, filter => [:something_else]) }.to raise_error(ArgumentError, /must be a/i)
    end
  end

  it 'will only accept a single level of tag filter nesting' do
    filters = nodule.known_filters.select { |filter| filter.to_s =~ /tag/ }

    filters.each do |filter|
      expect { nodule.find_test_cases(@root, @target, filter => ['@some_value', [/nested_pattern/]]) }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => ['@some_value', [/nested_pattern/, ['way_too_nested']]]) }.to raise_error(ArgumentError, /cannot.* nested/i)
    end
  end

  it 'will only accept string, regular expression, or collections thereof as path filters' do
    filters = nodule.known_filters.select { |filter| filter.to_s =~ /path/ }

    filters.each do |filter|
      expect { nodule.find_test_cases(@root, @target, filter => '@some_value') }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => /some_pattern/) }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => ['@some_value', /some_pattern/]) }.to_not raise_error
      expect { nodule.find_test_cases(@root, @target, filter => :something_else) }.to raise_error(ArgumentError, /must be a/i)
      expect { nodule.find_test_cases(@root, @target, filter => [:something_else]) }.to raise_error(ArgumentError, /must be a/i)
    end
  end

  it 'treats an empty filter set as if the filter were not provided' do
    filters = nodule.known_filters

    filters.each do |filter|
      not_provided = nodule.find_test_cases(@root, @target)

      case
        when filter.to_s =~ /path/
          nothing_provided = nodule.find_test_cases(@root, @target, filter => [])
        when filter.to_s =~ /tag/
          nothing_provided = nodule.find_test_cases(@root, @target, filter => [])
        else
          raise(ArgumentError, "Unknown filter '#{filter}'")
      end

      expect(nothing_provided).to eq(not_provided)
      expect(nothing_provided).to_not be_empty
    end
  end

  it 'can combine any and all filters' do
    filters = nodule.known_filters

    applied_filters = {excluded_tags: '@a',
                       included_tags: /./,
                       excluded_paths: 'aaa',
                       included_paths: /./,
    }

    # A reminder to update this test if new filters are added in the future
    expect(applied_filters.keys).to match_array(filters)


    expect { @search_output = nodule.find_test_cases(@root, @target, applied_filters) }.to_not raise_error
    expect(@search_output).to be_an(Array)
    expect(@search_output).to_not be_empty
  end

  it 'complains if given an unknown filter' do
    expect { nodule.find_test_cases(@root, @target, 'not a filter' => 'filter value') }.to raise_error(ArgumentError, /unknown filter/i)
  end

  it 'can search an empty feature file' do
    test_file = "#{@default_file_directory}/a_test.feature"
    File.open(test_file, 'w') { |file| file.write('') }

    expect { nodule.find_test_cases(@default_file_directory, '.') }.to_not raise_error
  end

  it 'can search a feature that has no tests' do
    test_file = "#{@default_file_directory}/a_test.feature"
    File.open(test_file, 'w') { |file| file.write('Feature: Empty feature') }

    expect { nodule.find_test_cases(@default_file_directory, '.') }.to_not raise_error
  end

  it 'can search a single directory' do
    expect { nodule.find_test_cases(@root, @target) }.to_not raise_error
  end

  it 'can search multiple directories' do
    expect { nodule.find_test_cases(@root, [@target, @target]) }.to_not raise_error
  end

  it 'complains if told to search a non-existent location' do
    expect { nodule.find_test_cases(@root, 'does/not/exist') }.to raise_error(ArgumentError, /does not exist/)
  end

  it 'complains if given something besides a place to search' do
    expect { nodule.find_test_cases(@root, '.') }.to_not raise_error
    expect { nodule.find_test_cases(@root, ['.', '.']) }.to_not raise_error
    expect { nodule.find_test_cases(@root, :bad) }.to raise_error(ArgumentError, /must be a/)
    expect { nodule.find_test_cases(@root, nil) }.to raise_error(ArgumentError, /must be a/)
  end

  describe 'filtering' do

    before(:each) do
      test_file = "#{@default_file_directory}/a_test.feature"
      file_text = "Feature:
                     @tag_1
                     Scenario:
                       * a step

                     @tag_2
                     Scenario:
                       * a step

                     @tag_22
                     Scenario:
                       * a step"
      File.write(test_file, file_text)

      test_file = "#{@default_file_directory}/another_test.feature"
      file_text = "Feature:
                     Scenario:
                       * a step"
      File.write(test_file, file_text)
    end


    describe 'tag filtering' do

      context 'including tags' do

        let(:filter) { :included_tags }

        it 'can extract regular expressions from string arguments' do
          found_tests = nodule.find_test_cases(@default_file_directory, '.', filter => '/2/')

          expect(found_tests).to match_array(["./a_test.feature:7", "./a_test.feature:11"])
        end

      end

      context 'excluding tags' do

        let(:filter) { :excluded_tags }

        it 'can extract regular expressions from string arguments' do
          found_tests = nodule.find_test_cases(@default_file_directory, '.', filter => '/2/')

          expect(found_tests).to match_array(["./a_test.feature:3", "./another_test.feature:2"])
        end

      end

    end

    describe 'path filtering' do

      context 'including paths' do

        let(:filter) { :included_paths }

        it 'can extract regular expressions from string arguments' do
          found_tests = nodule.find_test_cases(@default_file_directory, '.', filter => '/other/')

          expect(found_tests).to match_array(["./another_test.feature:2"])
        end

      end

      context 'excluding paths' do

        let(:filter) { :excluded_paths }

        it 'can extract regular expressions from string arguments' do
          found_tests = nodule.find_test_cases(@default_file_directory, '.', filter => '/other/')

          expect(found_tests).to match_array(["./a_test.feature:3", "./a_test.feature:7", "./a_test.feature:11"])
        end

      end

    end
  end

end
