Feature: Task structure

  Scenario: Tasks are created according to the TEF standard
    Given a created task
    Then the task contains, at least, the following pieces:
      | required_key | expected_value                                                                  |
      | type         | task                                                                            |
      | task_type    | cucumber                                                                        |
      | guid         | /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/ |
      | task_data    | <non-null>                                                                      |
      | resources    | /^.+(?:\\\|.+)*$/                                                               |

  Scenario: Tasks have their request data mapped

  Note: This request has explicit tests at both the queuebert request level and the cucumber command
  line option level. This will result in the command line paths to be added to every single test task
  created for the request.

    Given the following suite request:
      """
      {
        "name":                 "Request Foo",
        "owner":                "Owner Bar",
        "dependencies":         "foo|bar",
        "tests":                ["test_feature.feature:1"],
        "priority":             "1",
        "time_limit":           "2",
        "suite_guid":           "3",
        "command_line_options": {"file_paths": ["some.file"],
                                 "option_key": "option value"},
        "root_location":        "F:/bar",
        "working_directory":    "baz",
        "gemfile":              "buzz",
        "tag_exclusions":       ["@foo","@bar"],
        "tag_inclusions":       "/buzz/",
        "path_exclusions":       ["filtered_path"],
        "path_inclusions":       ["/filtered/"]
      }
      """
    When a task is created for it
    Then the created task matches the following:
    """
      {
        "type":          "task",
        "task_type":     "cucumber",
        "guid":          "<some guid>",
        "task_data":     {"cucumber_options": {"file_paths": ["some.file", "test_feature.feature:1"],
                                               "option_key": "option value"},
                          "root_location": "F:/bar",
                          "working_directory": "baz",
                          "gemfile": "buzz"},
        "resources":     "foo|bar",
        "priority":      "1",
        "time_limit":    "2",
        "suite_guid":    "3"
      }
      """

  Scenario: Missing data is not mapped
    Given the following suite request:
      """
      {
        "name":                 "Request Foo",
        "owner":                "Owner Bar",
        "dependencies":         "foo|bar",
        "tests":                ["test_feature.feature:1"]
      }
      """
    When a task is created for it
    Then the created task matches the following:
      """
      {
        "type":       "task",
        "task_type":  "cucumber",
        "guid":       "<some guid>",
        "task_data":  {"cucumber_options": {"file_paths": ["test_feature.feature:1"]}},
        "resources":  "foo|bar"
      }
      """
