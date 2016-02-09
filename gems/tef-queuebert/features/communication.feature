Feature: Communication

  Queuebert uses a messaging service to communicate with other components of the TEF.


  Scenario: Creates message endpoints on startup
    Given message queues for Queuebert have not yet been created
    And message exchanges for Queuebert have not yet been created
    When Queubert is started
    Then message queues for Queuebert have been created
    And message exchanges for Queuebert have been created

  Scenario: Default endpoint names

  Note: The default endpoint names incorporate the current environment (e.g. dev/test/prod)

    Given the following message queues have not been yet been created:
      | tef.<env>.queuebert.request |
    And the following message exchanges have not been yet been created:
      | tef.<env>.queuebert_generated_messages |
    When Queubert is started
    Then the following message queues have been created:
      | tef.<env>.queuebert.request |
    And the following message exchanges have been created:
      | tef.<env>.queuebert_generated_messages |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.queuebert.request |
    And the following message exchanges have not been yet been created:
      | my_custom.prefix.queuebert_generated_messages |
    And a name prefix of "my_custom.prefix"
    When Queubert is started
    Then the following message queues have been created:
      | my_custom.prefix.queuebert.request |
    And the following message exchanges have been created:
      | my_custom.prefix.queuebert_generated_messages |

  Scenario: Custom endpoint names
    Given the following message queues have not been yet been created:
      | special.request.queue |
    And the following message exchanges have not been yet been created:
      | special.message.exchange |
    And a request queue name of "special.request.queue"
    And an output exchange name of "special.message.exchange"
    When Queubert is started
    Then the following message queues have been created:
      | special.request.queue |
    And the following message exchanges have been created:
      | special.message.exchange |
