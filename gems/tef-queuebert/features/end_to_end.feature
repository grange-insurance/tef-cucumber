Feature: Task suite creation

  Queuebert receives requests for test suites which it then creates based upon the information provided in
  the request. These suites are, in turn, forwarded onto the manager for dispatching.


  Scenario: Creating a test suite
    Given Queuebert is running
    When a request for a test suite is received
    Then a suite is created and sent to the manager
    And a suite notification is sent to the keeper
