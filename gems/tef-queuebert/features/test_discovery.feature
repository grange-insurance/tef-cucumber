Feature: Test discovery

  Instead of being explicitly told which tests to include in a suite, Queuebert can discover them dynamically.


  Scenario: Discovering tests in a directory
    Given the directory "test_directory"
    And the following feature file "a_test.feature":
      """
      Feature: A test feature

        Scenario Outline: Test 1
          * some steps
        Examples:
          | param | value |
          | a     | 1     |
          | b     | 2     |
      """
    And the directory "test_directory/nested_directory"
    And the following feature file "another_test.feature":
      """
      Feature: Another test feature

        Scenario: Test 2
          * some steps
      """
    When "test_directory" is searched for tests
    Then the following test cases are discovered for "test_directory":
      | test_directory/a_test.feature:7                        |
      | test_directory/a_test.feature:8                        |
      | test_directory/nested_directory/another_test.feature:3 |

  Scenario: Discovering tests in an 'empty' directory
    Given the directory "test_directory"
    And the following feature file "empty.feature":
      """
      Feature: WIP
      """
    And the following feature file "really_empty.feature":
      """
      """
    And the following feature file "not_a_feature.file":
      """
      Some other kind of file.
      """
    And the directory "test_directory/empty_directory"
    When "test_directory" is searched for tests
    Then no test cases are discovered for "test_directory"
