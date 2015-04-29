# Catchy Title??

In an ideal world, everyone who makes Rails apps would do test-driven development, but many do not do so due to the complexity of setup, the additional time it takes to write tests, and general laziness.  I believe that by providing simple, powerful tools and the guidance in using them, at least the first two factors can be eliminated, and general laziness will become reason TO write tests rather than a reason NOT TO write tests.

What is described here is feature-driven development, which is a natual extension of test-driven and behavior-driven development.  The idea is to start by writing a computer-and-human-readable description of the features of our app, the implement those features step-by-step, unit-testing each component as it is written.  The failing or pending tests tell us what we need to implement next.  When a feature specification and all of its unit tests are passing, you'll know the feature is complete.

In order to follow this tutorial, you'll need a basic understanding of Rails, and it will help if you've done a bit of testing with RSpec.  The tools used are:

- RSpec, a very widely-used testing framework for Ruby.  http://rspec.info/
- Simple BDD, a small frameowrk that greatly simplifies writing feature specs, which are the linchpin of BDD.
- Capybara, a web driver that lets your feature specs act as if they were in a browser.
- FactoryGirl, a replacement for fixtures that makes it easy to create dynamic data for your tests

## Basic Setup

- Create a new Rails application.  Make sure you pass the -T flag to rails new to avoid generating the default testing infrastructure.
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
This will add all of the tools described above to your testing stack.

## Describing Features

A feature spec defines one feature, which is a subset of the functionality of your application.  Each feature has one or more scenarios; a scenario might describe a single aspect of the feature, or a path through the feature.  Each scenario is composed of one more more steps, which describe the user story for the scenario.  Each step begins with one of the following words: Given, When, Then, And, But and is followed by a string explaining the step in human-understandable language.

In order to have an authentication system, users will need to be able to sign up, log in, and log out.  A feature spec for the user management could live in spec/features/user_management_spec.rb and look like this:

```ruby
require 'rails_helper'

feature "User management" do
  scenario "account registration" do
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

  def i_visit_the_login_page
    visit new_session_path
  end
end
```

A few things to note about this feature spec:
- It is written in something that closely resembles English.  In a work situation, you'll often have a product manager with a vision of what needs to be developed; by sharing this spec with him or her, you can ensure that you have a mutual understanding of what is being built.
- You could write your steps in any language supported by Ruby, but Simple BDD only supports English for the initial word.  If your code is in Spanish, you'd have to write When "inicie sesión", not Cuando "inicie sesión".
- Each line describes an action that may take many steps to accomplish in the UI.  It is important to ensure your feature specs do not follow your UI too closely, or you will end up rewriting them with every change to the UI.
- Your feature specs all live under the spec/features/ directory.  You may add subdirectories to this directory, and you may name the files whatever you wish, as long as they end in _spec.rb

Once this file is in place, run your specs.  Since we've defined scenarios and steps but not implemented the steps, you'll get pending specs like this:

```
  1) User management account registration
     # i_create_an_account
     Failure/Error: When "I create an account"
     SimpleBdd::StepNotImplemented:
       i_create_an_account
```

The last line above contains the method you'll need to implement in order for that step to work.  Let's do that, within the feature block but outside the scenario blocks:

```
  let(:username) { FactoryGirl.generate(:username) }
  let(:password) { 'password1' }

  def i_create_an_account
    visit new_user_path
    fill_in 'Username', with: username
    fill_in 'Password', with: password
    click_button 'Register'
  end
```

A couple of things here need explanation:
- let is the way RSpec defines variables that need to be shared across steps.  It is also possible to use instance variables for this purpose, but let variables can all be defined in one place, so many developers find them easier to keep track of as feature specs grow large.
- The step function contains several Capybara commands.  visit instructs the virtual browser to go to the specified path.  You can specify the path by relative URL ('/session/new') or using Rails URL helpers, as I've done here.  fill_in causes the virtual browser to put text into a form field specified by label text, name, or css id, and click clicks a button.

If you run this spec, you'll get an error:

```
1) User management account registration
     Failure/Error: visit new_user_path
     NameError:
       undefined local variable or method `new_user_path' for #<RSpec::ExampleGroups::UserManagement:0x007fa2f0b2a7d8>
```

This tells us the next step in our development: the URL helper is missing, so add a route!  Add the following to config/routes.rb:

```ruby
resources :users
```

Re-running the spec will give you a new error:

```
1) User management account registration
     Failure/Error: visit new_user_path
     ActionController::RoutingError:
       uninitialized constant UsersController
```

It's time to build a controller!  While feature specs are intended to be very high-level, controllers and models are unit-tested, so we want to examine every case we can think of.  Controller specs live under spec/controllers/ and are named by the controller they are testing.  Here's spec/controllers/users_controller_spec.rb, which tests the :new action:

```ruby
require 'rails_helper'

describe UsersController do
  describe '#new' do
    before do
      get :new
    end

    it "assigns a blank user" do
      expect(assigns(:user)).to be_a User
      expect(assigns(:user)).to_not be_persisted
    end

    it "is sucessful" do
      expect(response).to be_success
    end

    it "renders the new user page" do
      expect(response).to render_template(:new)
    end
  end
end
```

If you run this spec, it will fail for the same reason our feature spec failed:  We don't have a UsersController yet.  Let's add one with a new action in app/controllers/users_controller.rb:

```ruby
class UsersController < ApplicationController
  def new
    @user = User.new
    render :new
  end
end
```

If you run your specs again (which you should do after implementing anything), you'll see a new error:

```
1) UsersController#new assigns a blank user
     Failure/Error: get :new
     NameError:
       uninitialized constant UsersController::User
```

We need a User model.  Generate one:

```
rails g model user username:string password_digest:string
```

This will generate both the class and the model spec.  Add has_secure_password to the model, so it looks like this:

```ruby
class User < ActiveRecord::Base
  has_secure_password
  validates :username, uniqueness: true
end
```

Leave the model spec pending; there's nothing to test here that isn't already in ActiveRecord's tests.  Migrate and run your specs again:

```
4) User management account registration
     Failure/Error: visit new_user_path
     ActionView::MissingTemplate:
       Missing template users/new, application/new with {:locale=>[:en], :formats=>[:html], :variants=>[], :handlers=>[:erb, :builder, :raw, :ruby]}. Searched in:
```

Like before, RSpec is telling you what to do next:  Make a view!  The following goes in app/views/users/new.html.erb, and should look familiar to anyone who has done a Rails tutorial:

```erb
<%= form_for @user do |f| %>
  <p>
    <%= f.label :username %>
    <%= f.text_field :username %>
  </p>
  <p>
    <%= f.label :password %>
    <%= f.text_field :password %>
  </p>
  <p>
    <%= f.label :password_confirmation %>
    <%= f.text_field :password_confirmation %>
  </p>
  <p>
    <%= f.submit 'Register' %>
  </p>
<% end %>
```

Now that the new action on UsersController works, we can go back to the feature spec.  When capybara attempts to fill in the new user form, it encounters the FactoryGirl sequence we specified above.  Not finding it, we get the following error:

```
1) User management account registration
     Failure/Error: let(:username) { FactoryGirl.generate(:username) }
     ArgumentError:
       Sequence not registered: username
```

We don't have any factories yet, so we'll need to set one up.  Factories live in spec/factories, and since the one here applies to users, we can create it in spec/factories/user_factory.rb:

```ruby
FactoryGirl.define do
  sequence(:username) { |n| "user#{n}" }
end
```

This factory will allow your feature spec to create nonrandom unique usernames.  Run the spec, and capybara will get as far as clicking the 'Register' button on your new user form, when it realizes that the button doesn't do anything yet:

```
1) User management account registration
     Failure/Error: click_button 'Register'
     AbstractController::ActionNotFound:
       The action 'create' could not be found for UsersController
```

You're probably beginning to notice a pattern.  You can continue in this fashion until you run out of ideas.  The abstracted process is:

1. Write a feature spec
2. Implement the next pending step
3. Fix the test failures caused by the step
4. Repeat (2) and (3) until the feature spec passes

As you're working, don't be afraid to refactor feature specs as you find better ways to implement your features, and definitely clean up any code that is associated with passing tests.  When you've finished, you will have an application that is well-tested, well-documented, and can easily be extended.  This repository contains a blog application that was developed using this technique; it can be used as sample code and a starting point for many different types of Rails applications.  Note that it is completely unstyled; when I develop applications in this fashion, I tend not to even run rails server until I'm done working on features, but if you're more front-end-oriented, you'll probably want to write CSS as you go along.

Happy featuring!
