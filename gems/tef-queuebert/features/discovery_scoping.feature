Feature: Discovery scoping

When discovering tests, Queuebert can limit what it finds by restricting filepath and/or tags associated with
a test. Exclusive filters will filter out any test case that matches the filter, whereas inclusive filters
will filter out non-matching test cases. Filters can be strings or regular expressions.


  Background:
    Given the directory "test_directory"
    And the following feature file "a_test.feature":
      """
      @feature_tag_1
      Feature: The first feature

        @test_tag_1
        Scenario: a scenario
          * a step

        @test_tag_2
        Scenario Outline: an outline
          * a step
        @example_tag_1
        Examples: example set 1
          | param   |
          | value 1 |
        @example_tag_2
        Examples: example set 2
          | param   |
          | value 2 |
      """
    And the directory "test_directory/nested_directory"
    And the following feature file "another_test.feature":
      """
      @feature_tag_2
      Feature: The second feature

        @test_tag_3
        Scenario: another scenario
          * a step

        @test_tag_4
        Scenario Outline: another outline
          * a step
        @example_tag_3
        Examples: example set 3
          | param   |
          | value 3 |
        @example_tag_4
        Examples: example set 4
          | param   |
          | value 4 |
      """


  Scenario: Restricting discovery by excluded tags
    When "test_directory" is searched for tests using the following tag filters:
      | filter type | filter                    |
      | excluded    | @feature_tag_1\|/example/ |
    Then the following test cases are discovered for "test_directory":
      | test_directory/nested_directory/another_test.feature:5 |

  Scenario: Restricting discovery by included tags
    When "test_directory" is searched for tests using the following tag filters:
      | filter type | filter                  |
      | included    | @feature_tag_1\|/tag_3/ |
    Then the following test cases are discovered for "test_directory":
      | test_directory/a_test.feature:5                         |
      | test_directory/a_test.feature:14                        |
      | test_directory/a_test.feature:18                        |
      | test_directory/nested_directory/another_test.feature:5  |
      | test_directory/nested_directory/another_test.feature:14 |

  Scenario: Restricting discovery by included path
    When "test_directory" is searched for tests using the following path filters:
      | filter type | filter                                                       |
      | included    | path/to/test_directory/nested_directory/another_test.feature |
    Then the following test cases are discovered for "test_directory":
      | test_directory/nested_directory/another_test.feature:5  |
      | test_directory/nested_directory/another_test.feature:14 |
      | test_directory/nested_directory/another_test.feature:18 |

  Scenario: Restricting discovery by excluded path
    When "test_directory" is searched for tests using the following path filters:
      | filter type | filter   |
      | excluded    | /nested/ |
    Then the following test cases are discovered for "test_directory":
      | test_directory/a_test.feature:5  |
      | test_directory/a_test.feature:14 |
      | test_directory/a_test.feature:18 |

  Scenario: Combining filters
    Given the following tag filters:
      | filter type | filter      |
      | excluded    | @test_tag_4 |
    And the following path filters:
      | filter type | filter   |
      | included    | /nested/ |
    When "test_directory" is searched for tests
    Then the following test cases are discovered for "test_directory":
      | test_directory/nested_directory/another_test.feature:5 |

  Scenario: Valid filters
    * The following filter types are possible:
      | included_tags  |
      | excluded_tags  |
      | included_paths |
      | excluded_paths |
