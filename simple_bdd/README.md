# Catchy Title??

In an ideal world, everyone who makes Rails apps would do test-driven development, but many do not do so due to the complexity of setup, the additional time it takes to write tests, and general laziness.  I believe that by providing simple, powerful tools and the guidance in using them, at least the first two factors can be eliminated, and general laziness will become reason TO write tests rather than a reason NOT TO write tests.  Two gems, the very well-knwon RSpec and the not-so-well-known-yet Simple BDD are among these tools, and this blog post is the guidance.  We're going to develop a blog application, just like every other Rails tutorial, but we're going to do so using TDD/BDD techniques to ensure our application is well-tested AND covers all of the proposed features.

What is described here is feature-driven development.  We are going to start by writing a computer-readable description of the features of our blog, the implement those features step-by-step, unit-testing each component as it is written.  When a feature specification and all of its unit tests are passing, you'll know the feature is complete.

In order to follow this tutorial, you'll need a basic understanding of Rails, and it will help if you've done a bit of testing with RSpec.

## Basic Setup

- Create a new Rails application
- Add the following to your Gemfile and run bundle install:
```ruby
group :test do
  gem 'capybara-webkit'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'simple_bdd'
end
```
- Install RSpec:
```
rails g rspec:install
```
- Configure your testing stack by changing your spec/rails_helper.rb file to the following:
```ruby
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'capybara/email/rspec'
require 'simple_bdd/rspec'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.include Features::Steps, type: :feature

  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)

    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```
This will add several useful tools to RSpec's repertoire:
- Simple BDD for feature specs
- Capybara to imitate a web browser for integration testing
- DatabaseCleaner to keep your tests from interfering with one another
- FactoryGirl to provide example ActiveRecord models to your tests

## Describing Features

Our blog is going to need to have users.  Those users will need to be able to sign up, log in, and log out.  A feature spec for the user management looks like this:

```ruby
feature "User management" do
  scenario "account registration" do
    Given "I visit the login page"
    When "I create an account"
    Then "I am shown to be logged in"
  end
  
  scenario "logging in" do
    Given "I have an account"
    When "I log in with my email and password"
    Then "I am shown to be logged in"
  end
  
  scenario "logging out" do
    Given "I have an account"
    And "I am logged in"
    When "I log out"
    Then "I am not shown to be logged in"
  end
end
```

A couple of things to note about this feature spec:
- It is written in something that closely resembles plain English.  In a work situation, you'll likely have a product manager with a vision of what needs to be developed; by sharing this spec with him or her, you can ensure that you have a mutual understanding of what is being built.
- Each line describes an action that may take many steps to accomplish in the UI.  It is important to ensure your feature specs do not follow your UI too closely, or you will end up rewriting them with every change to the UI.
