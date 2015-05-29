Feature: Communication stability

  Since Queuebert is meant to be a long running application, it is likely that situations will arise where
  its message service becomes temporarily unavailable (e.g. looses connection, restarts, etc.). In these
  cases, it is important that Queuebert can smoothly reconnect and resume its previous work without loss
  of message data.


  Scenario: Message queues persist through message service loss
    Given Queubert is started
    And messages queues are available
    When the message service goes down
    And the message service comes up
    Then the message queues are still available
    And Queuebert can still receive and send messages through them


  @wip
  Scenario: Outgoing messages persist through message service loss

  @wip
  Scenario: Incoming messages persist through Queuebert loss
