Feature: Task Storage

  Being specifically designed to handle Cucumber tasks, the keeper stores test relevant information for later use.


  Background:
    * The following attributes are tracked for a scenario
      | task_guid   |
      | suite_guid  |
      | feature_id  |
      | name        |
      | line_number |
      | end_time    |
      | runtime     |
      | steps       |
      | done        |
      | status      |
      | exception   |
    * The following attributes are tracked for a feature
      | suite_guid |
      | name       |
      | filename   |
    * The following attributes are tracked for a suite
      | guid           |
      | name           |
      | requested_time |
      | finished_time  |
      | complete       |

  Scenario: Storing scenario attributes
    Then there is a place to store the scenario's attributes

  Scenario: Storing feature attributes
    Then there is a place to store the features's attributes

  Scenario: Storing test suite attributes
    Then there is a place to store the test suite's attributes

  Scenario: Storing a test result
    Given a test result with data
    When the result is processed by the keeper
    Then the result's information is stored
