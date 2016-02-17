Feature: Task suite creation

  Queuebert receives requests for test suites which it then creates based upon the information provided in
  the request. These suites are, in turn, forwarded onto the manager for dispatching.


  Background:
    Given the directory "path/to/root/tests/live/here/dir_foo"
    And the following feature file "a_test.feature":
      """
      Feature: A test feature

        Scenario: Test 1
          * some steps

        @tag_1 @tag_2
        Scenario: Test 2
          * some steps
      """
    And the directory "path/to/root/tests/live/here/dir_bar"
    And the following feature file "another_test.feature":
      """
      Feature: Another test feature

        Scenario: Test 3
          * some steps

        @tag_1 @tag_44
        Scenario: Test 4
          * some steps

        @tag_1 @tag_2
        Scenario: Test 5
          * some steps
      """
    And the directory "path/to/root/tests/live/here/dir_baz"
    And the following feature file "yet_another_test.feature":
      """
      Feature: Yet another test feature

        @tag_1 @tag_3
        Scenario: Test 6
          * some steps

        @tag_1 @tag_44
        Scenario: Test 7
          * some steps
      """


  Scenario: Handling a complex suite request
    Given Queuebert is running
    When the following request for a test suite is sent to it:
      """
      {
        "name":                  "A complex request",
        "owner":                 "You",
        "suite_guid":            "123456",
        "test_directory":        "tests/live/here",
        "tests":                 ["foo.feature", "bar.feature:99"],
        "directories":           ["dir_foo","dir_bar","dir_baz"],
        "tag_inclusions":        ["@tag_1",["@tag_2","@tag_3","@tag_44"]],
        "tag_exclusions":        ["/4/"],
        "path_inclusions":       ["dir_bar","dir_baz"],
        "path_exclusions":       ["/az/"],
        "working_directory":     "tests/run/here",
        "root_location":         "path/to/root",
        "dependencies":          ["thing_1","thing_2"],
        "command_line_options":  {"options":"--quiet"},
        "gemfile":               "tests/gemfile",
        "priority":              "7",
        "env":                   "env_foo"
      }
      """
    And messages have been sent out in response
    Then the following message was sent and routed with "task":
      """
      {
        "type":       "task",
        "task_type":  "cucumber",
        "guid":       "<some guid>",
        "resources":  ["thing_1","thing_2"],
        "task_data":  {"cucumber_options": {"file_paths": ["tests/live/here/foo.feature"],
                                            "options": "--quiet"},
                       "root_location": "path/to/root",
                       "working_directory": "tests/run/here",
                       "gemfile": "tests/gemfile"},
        "suite_guid": "123456",
        "priority":   "7"
      }
      """
    And the following message was sent and routed with "task":
      """
      {
        "type":       "task",
        "task_type":  "cucumber",
        "guid":       "<some guid>",
        "resources":  ["thing_1","thing_2"],
        "task_data":  {"cucumber_options": {"file_paths": ["tests/live/here/bar.feature:99"],
                                            "options": "--quiet"},
                       "root_location": "path/to/root",
                       "working_directory": "tests/run/here",
                       "gemfile": "tests/gemfile"},
        "suite_guid": "123456",
        "priority":   "7"
      }
      """
    And the following message was sent and routed with "task":
      """
      {
        "type":       "task",
        "task_type":  "cucumber",
        "guid":       "<some guid>",
        "resources":  ["thing_1","thing_2"],
        "task_data":  {"cucumber_options": {"file_paths": ["tests/live/here/dir_bar/another_test.feature:11"],
                                            "options": "--quiet"},
                       "root_location": "path/to/root",
                       "working_directory": "tests/run/here",
                       "gemfile": "tests/gemfile"},
        "suite_guid": "123456",
        "priority":   "7"
      }
      """
    And  the following message was sent and routed with "suite":
      """
      {
        "type":             "suite_creation",
        "suite_guid":       "123456",
        "name":             "A complex request",
        "owner":            "You",
        "task_ids":         ["<task_id>", "<task_id>", "<task_id>"],
        "env":              "env_foo",
        "requested_time":   "<now>",
        "test_count":       "3"
      }
      """
    And no other messages were sent
