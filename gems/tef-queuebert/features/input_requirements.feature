Feature: Suite requests

  Suite requests have a specific format.


  Background:
    Given a queue to receive from
    And an exchange to publish to


  Scenario Outline: Queuebert accepts a properly structured request
  Note: At least one of 'tests', 'directories', or 'test_directory' must be provided.

    When the following suite request is received:
      """
      {
        "name": "Need this one",
        "dependencies": ["and","these"],
        "root_location": "path/to",
        "<one_of>": <these>,
        "other": "optional stuff"
      }
      """
    Then the request is accepted
  Examples:
    | one_of         | these |
    | tests          | []    |
    | directories    | []    |
    | test_directory | "."   |

  Scenario: Queuebert rejects an improperly structured request
    When the following suite request is received:
      """
      {
        "missing": "required keys"
      }
      """
    Then the request is rejected

  Scenario: Rejected requests are given the correct request structure
    When a suite request is rejected
    Then rejection response includes the correct request format:
      """
      {
        "name":                 "required",
        "owner":                "optional",
        "dependencies":         "required",
        "command_line_options": "optional",
        "root_location":        "optional",
        "test_directory":       "required",
        "tests":                "required(array)",
        "directories":          "required(array)",
        "tag_exclusions":       "optional",
        "tag_inclusions":       "optional",
        "path_exclusions":       "optional",
        "path_inclusions":       "optional"
      }
      """

  Scenario: No tasks are created for invalid requests
    When the following suite request is received:
      """
      {
        "missing": "required keys",
        "tests": ["a:7"]
      }
      """
    Then no suite is created or sent to the manager

  #todo - need to ack/nack messages?
