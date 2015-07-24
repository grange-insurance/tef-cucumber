Feature: Test feature 1

  Scenario: Test 1
    * echo "Test 1 is happening"

  Scenario Outline: Test 4 through 5
    * echo "<message>"
  Examples:
    | message             |
    | Test 4 is happening |
    | Test 5 is happening |
