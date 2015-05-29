Feature: Task suite creation

  Upon determining a set of tests that need to be executed, Queuebert will automatically create the
  associated tasks.

  The tests from which to create tasks can be explicitly provided or determined dynamically from
  given directories. In either case, a base test directory can be provided that will cause the given
  test/directory paths to be treated as relative to this location.

  In all cases, paths are further relative to a root location that can be provided in the request or
  configured on the machine that is running Queuebert. This allows multiple mirrored test directories
  to exists in different places and still work. For example a test directory of 'project_dir/features'
  might live off of 'C:\' on the machine where Queuebert will search for them while the same files
  live off of 'T:\' on the machine where the tests will be executed by a worker.


  Background:
    Given a queue to receive from
    And queues to publish to
    And a location "root_dir"
    And the directory "root_dir/test_directory_1"
    And the following feature file "a_test.feature":
      """
      Feature: A test feature

        Scenario: Test 1
          * some steps

        Scenario: Test 2
          * some steps
      """
    And the directory "root_dir/test_directory_2"
    And the following feature file "another_test.feature":
      """
      Feature: Another test feature

        Scenario: Test 3
          * some steps
      """
    And the directory "root_dir/test_directory_3"
    And the following feature file "yet_another_test.feature":
      """
      Feature: Yet another test feature

        Scenario: Test 4
          * some steps
      """
    And the directory "root_dir/test_directory_3/test_directory_4"
    And the following feature file "a_final_test.feature":
      """
      Feature: A final test feature

        Scenario: Test 5
          * some steps

        Scenario: Test 6
          * some steps
      """
    And all of that stuff is in "other_root" as well
    And a root location of "root_dir"

  Scenario: Explicit test set
    Given the following tests need tasks created for them:
      | test_directory_1/a_test.feature:6       |
      | test_directory_2/another_test.feature:3 |
    When a request for the test suite is received
    Then tasks have been created for the following tests:
      | test_directory_1/a_test.feature:6       |
      | test_directory_2/another_test.feature:3 |

  Scenario: Discovered test set
    Given the following directories need tasks created for them:
      | test_directory_1 |
      | test_directory_2 |
    When a request for the test suite is received
    Then tasks have been created for the following tests:
      | test_directory_1/a_test.feature:3       |
      | test_directory_1/a_test.feature:6       |
      | test_directory_2/another_test.feature:3 |

  Scenario: Combined discovered/explicit

  Note: A test which is explicitly added and also is discovered in an added directory will
  not have duplicate tasks created for it.

    Given the following tests need tasks created for them:
      | test_directory_1/a_test.feature:6                        |
      | test_directory_3/test_directory_4/a_final_test.feature:3 |
    Given the following directories need tasks created for them:
      | test_directory_3 |
    When a request for the test suite is received
    Then tasks have been created for the following tests:
      | test_directory_1/a_test.feature:6                        |
      | test_directory_3/yet_another_test.feature:3              |
      | test_directory_3/test_directory_4/a_final_test.feature:3 |
      | test_directory_3/test_directory_4/a_final_test.feature:6 |
    And the following tests have only a single task created for them:
      | test_directory_3/test_directory_4/a_final_test.feature:3 |

  Scenario: Specific test directory
    Given the following directories need tasks created for them:
      | test_directory_4 |
    And the following tests need tasks created for them:
      | yet_another_test.feature:3 |
    And a test directory of "test_directory_3"
    When a request for the test suite is received
    Then tasks have been created for the following tests:
      | test_directory_3/yet_another_test.feature:3              |
      | test_directory_3/test_directory_4/a_final_test.feature:3 |
      | test_directory_3/test_directory_4/a_final_test.feature:6 |

  Scenario: Only a test directory

  Lacking explicit tests or directories for which to create tasks, the provided test
  directory will then be treated as an explicit directory.

    Given no directories need tasks created for them
    And no tests need tasks created for them
    And a test directory of "test_directory_3"
    When a request for the test suite is received
    Then tasks have been created for the following tests:
      | test_directory_3/yet_another_test.feature:3              |
      | test_directory_3/test_directory_4/a_final_test.feature:3 |
      | test_directory_3/test_directory_4/a_final_test.feature:6 |

  Scenario: Specific root location
    Given the following directories need tasks created for them:
      | test_directory_4 |
    And the following tests need tasks created for them:
      | yet_another_test.feature:3 |
    And a test directory of "copy_of_test_directory_3"
    And a root location of "other_root"
    When a request for the test suite is received
    Then tasks have been created for the following tests:
      | copy_of_test_directory_3/yet_another_test.feature:3              |
      | copy_of_test_directory_3/test_directory_4/a_final_test.feature:3 |
      | copy_of_test_directory_3/test_directory_4/a_final_test.feature:6 |
