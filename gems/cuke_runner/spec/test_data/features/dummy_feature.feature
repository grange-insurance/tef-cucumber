Feature: Dummy feature for testing cuke_runner


  Scenario: Execute a passing test
    When  I run a test that passes
    Then  There will be a zero return code

  Scenario: Execute a failing test
    When  I run a test that fails
    Then  There will be a non-zero return code