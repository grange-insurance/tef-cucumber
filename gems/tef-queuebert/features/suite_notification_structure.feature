Feature: Suite notification structure

  In order to allow a keeper to better keep track of test results as an organized group (compared to the individual
  manner in which it receives them), queuebert sends notifications to it that contain information about the test suite
  in total. Depending on the size of the test suite, this may take several notification messages in order to
  communicate all of the relevant data.


  Background:
    Given a queue to receive from
    And an exchange to publish to


  Scenario: Initial suite creation notification
    Given the following suite request:
      """
      {
        "name":                 "Request Foo",
        "dependencies":         "",
        "owner":                "Owner Bar",
        "tests":                ["test_feature.feature:1", "test_feature.feature:2", "test_feature.feature:3"],
        "env":                  "foo",
        "suite_guid":           "112233",
        "root_location":        "F:/bar"
      }
      """
    When a test suite is created for the request
    Then the following notification is sent and routed with "suite"
      """
      {
        "type":             "suite_creation",
        "suite_guid":       "112233",
        "name":             "Request Foo",
        "owner":            "Owner Bar",
        "task_ids":         ["<task_id_1>", "<task_id_2>", "<task_id_3>"],
        "env":              "foo",
        "requested_time":   "<now>",
        "test_count":       "3"
      }
      """

  Scenario: Suite update notification
    Given the following suite request:
      """
      {
        "name":                 "Request Foo",
        "dependencies":         "",
        "owner":                "Owner Bar",
        "tests":                [<lots of tests>],
        "env":                  "foo",
        "suite_guid":           "112233",
        "root_location":        "F:/bar"
      }
      """
    When a test suite is created for the request
    And the suite notification is sent and routed with "suite"
    Then at least one suite update notification is sent and routed with "suite":
      """
      {
        "type":          "suite_update",
        "suite_guid":    "112233",
        "task_ids":      [<some_number_of_task_ids>],
        "test_count":    "<total_test_count>"
      }
      """
    And the received notifications cumulatively contain all of the task ids for the test suite
