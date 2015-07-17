Feature: Task Storage

  Being specifically designed to handle Cucumber tasks, the keeper stores test relevant information for later use.


  Scenario: Storing scenario attributes
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

  Scenario: Storing feature attributes
    * The following attributes are tracked for a feature
      | suite_guid |
      | name       |
      | filename   |

  Scenario: Storing test suite attributes
    * The following attributes are tracked for a suite
      | guid           |
      | name           |
      | requested_time |
      | finished_time  |
      | complete       |
