Feature: Stability

  It is possible (likely, in fact) that invalid feature files will be encountered when searching for
  for tests. These files will not be included in search results. Although such files are a problem
  that should be fixed, ignoring one file is preferable to stopping the search and getting no results
  at all.


  Scenario: Bad feature files
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
    And the following feature file "got_some_typos.feature":
      """
      Feature: There was...

      Scenario: an earth shattering...


      @KaBoom!!!
      """
    And the following feature file "another_test.feature":
      """
      Feature: Another test feature

        Scenario: Test 2
          * some steps
      """
    When "test_directory" is searched for tests
    Then the following test cases are discovered for "test_directory":
      | test_directory/a_test.feature:7       |
      | test_directory/a_test.feature:8       |
      | test_directory/another_test.feature:3 |
