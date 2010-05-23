Feature: Load resources from different sources
  In order to make it easy to load resources from anywhere they may be found
  As a cucumber developer
  I want a way to use resource loaders and write my own

  Background:
    Given a standard Cucumber project directory structure
    And a file named "features/remote_1.feature" with:
      """
      Feature: First Remote Feature

        Scenario: First
          Given foo
          Then bar
      """
  
  @resource_server
  Scenario: Single resource via HTTP
    Given an http server on localhost:22225 is serving the contents of the features directory
    When I run cucumber --dry-run -f pretty http://localhost:22225/features/remote_1.feature
    Then it should pass with
      """
      Feature: First Remote Feature
  
        Scenario: First # http://localhost:22225/features/remote_1.feature:3
          Given foo     # http://localhost:22225/features/remote_1.feature:4
          Then bar      # http://localhost:22225/features/remote_1.feature:5

      1 scenario (1 undefined)
      2 steps (2 undefined)

      """
