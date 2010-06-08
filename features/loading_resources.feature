Feature: Load resources from different places
  In order to run features from wherever they are located
  As a cucumber developer
  I want many ways to load resources

  Background:
    Given a standard Cucumber project directory structure
    And a file named "features/remote_1.feature" with:
      """
      Feature: First Remote Feature

        Scenario: First
          Given foo
          Then bar
      """
    And a file named "features/remote_2.feature" with:
      """
      Feature: Second Remote Feature

        Scenario: Second
          Given baz
          Then qux
      """
    And a file named "features/feature.list" with:
      """
      http://localhost:22225/features/remote_1.feature
      http://localhost:22225/features/remote_2.feature
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

  @resource_server
  Scenario: Many resources via HTTP
    Given an http server on localhost:22225 is serving the contents of the features directory
    When I run cucumber --dry-run -f progress @http://localhost:22225/features/feature.list
    Then it should pass with
      """
      UUUU

      2 scenarios (2 undefined)
      4 steps (4 undefined)

      """

  @resource_server @wip
  Scenario: Loading resources via a plugin
    Given a fakeproto server on localhost:22225 is serving the contents of the features directory
    And a file named "features/support/fake_proto_plugin.rb" with:
      """
      require 'open-uri'
      require 'cucumber/plugin'

      class FakeProtoLoader
        extend Cucumber::Plugin
        register_input(self)

        def protocols
          [:fakeproto]
        end

        def read(uri)
          uri.gsub!(/^fakeproto/, 'http')
          open(uri).read
        end
      end
      """
    When I run cucumber --dry-run -f progress --plugin features/support/fake_proto_plugin.rb fakeproto://localhost:22225/features/remote_1.feature
    Then it should pass with
      """
      UU

      1 scenario (1 undefined)
      2 steps (2 undefined)

      """
