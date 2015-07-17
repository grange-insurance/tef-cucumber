And(/^The following attributes are tracked for a scenario$/) do |attributes|
  expected_column_names_array = attributes.raw.flatten

  found_column_names_array = TEF::CukeKeeper::Models::Scenario.column_names
  found_column_names_array.delete('id') # We don't care about the database's internal id column

  expect(found_column_names_array).to match_array expected_column_names_array
end

And(/^The following attributes are tracked for a suite$/) do |attributes|
  expected_column_names_array = attributes.raw.flatten

  found_column_names_array = TEF::CukeKeeper::Models::TestSuite.column_names
  found_column_names_array.delete('id') # We don't care about the database's internal id column

  expect(found_column_names_array).to match_array expected_column_names_array
end

And(/^The following attributes are tracked for a feature$/) do |attributes|
  expected_column_names_array = attributes.raw.flatten

  found_column_names_array = TEF::CukeKeeper::Models::Feature.column_names
  found_column_names_array.delete('id') # We don't care about the database's internal id column

  expect(found_column_names_array).to match_array expected_column_names_array
end
