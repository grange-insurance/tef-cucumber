Feature: Communication

  Queuebert uses a messaging service to communicate with other components of the TEF.


  Scenario: Creates queues on startup
    Given message in/out queues for Queuebert have not been yet been created
    When Queubert is started
    Then message in/out queues for Queuebert have been created

  Scenario: Default queue names

  Note: The default queue names incorporate the current environment (e.g. dev/test/prod)

    Given the following message queues have not been yet been created:
      | tef.<env>.queuebert.request  |
      | tef.<env>.task_queue.control |
      | tef.<env>.keeper.cucumber    |
    When Queubert is started
    Then the following message queues have been created:
      | tef.<env>.queuebert.request  |
      | tef.<env>.task_queue.control |
      | tef.<env>.keeper.cucumber    |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.queuebert.request  |
      | my_custom.prefix.task_queue.control |
      | my_custom.prefix.keeper.cucumber    |
    And a name prefix of "my_custom.prefix"
    When Queubert is started
    Then the following message queues have been created:
      | my_custom.prefix.queuebert.request  |
      | my_custom.prefix.task_queue.control |
      | my_custom.prefix.keeper.cucumber    |

  Scenario: Custom queue names
    Given the following message queues have not been yet been created:
      | special.request.queue |
      | task.queue            |
      | keeper.queue          |
    And a request queue name of "special.request.queue"
    And a task queue name of "task.queue"
    And a keeper queue name of "keeper.queue"
    When Queubert is started
    Then the following message queues have been created:
      | special.request.queue |
      | task.queue            |
      | keeper.queue          |
