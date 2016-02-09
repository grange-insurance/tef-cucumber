Feature: End to end acceptance testing

  Everything should work!


  Background: Clean workspace
    * no TEF nodes are running

  Scenario: Cucumber task
    Given a queuebert node is running
    And a configured manager node is running
    And cuke worker nodes are running
    And a configured cuke keeper node is running
    And all components have finished starting up
    When  a request for a test suite is sent
    Then results for the executed tests are stored by the keeper

  @wip
  Scenario: Cucumber task with Bundler
    Note: use the bundle daemon in this one
