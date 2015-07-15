# Getting the most out of SimpleBDD

In this final post, we will explore the differences between SimpleBDD and its primary competitor, Cucumber, and explore some tricks you can do to get the most out of SimpleBDD.

## Why SimpleBDD instead of Cucumber?
Cucumber is the tool most people think of when mentioning Behavior-Driven Development, with good reason, and BDD using Cucumber follows the same process as BDD using SimpleBDD.  There are three main differences between SimpleBDD and Cucumber:
- In Cucumber, step definitions are matched to steps using regular expressions. In SimpleBDD, step definitions are translated into method names.
- In Cucumber, step definitions are global.  In SimpleBDD, step definitions are called within the class context of the scenario that calls them.
- Cucumber is separate from RSpec, and your features and step definitions live outside the spec/ directory in your application.  SimpleBDD lives alongside RSpec, putting its files in spec/features, and the feature tests are run by default when you run RSpec.

The upshot of the design differences is that SimpleBDD encourages you to isolate each feature its step definitions, whereas Cucumber encourages you to share.  In small projects, Cucumber can be simpler, but in larger projects, step definitions tend to be spread across many files, making it difficult to figure out what you have already defined.  While both Cucumber and SimpleBDD use instance variables to share context across step definitions, large Cucumber projects tend to cause confusion about which instance variables are defined and what they mean unless you are quite careful about organizing your steps.  Since SimpleBDD makes you take specific measures to share steps across features, it's easier to keep track of these shared steps and what they define.

## Sharing step definitions

Since SimpleBDD features and scenarios each define a class context, shared steps can be included in modules.  These modules can be included in the spec/support directory, just like other RSpec shared code.  Add the following to the RSpec.configure block in rails_helper.rb:

```ruby
config.include Features::Steps, type: :feature
```

Now, say you want a shared step to log in.  Put the following in support/steps/user_steps.rb:

```ruby
module Features
  module Steps
    def i_am_logged_in
      visit new_session_path

      fill_in 'Username', with: current_user.username
      fill_in 'Password', with: current_user.password

      click_button 'Log in'
    end
  end
end
```

Once this is in place, you can do something like this in any feature spec:

```ruby
feature 'User Profile' do
  scenario 'Editing my profile' do
    Given 'I am logged in'
    .
    .
    .
  end
  
  let(:current_user) { FactoryGirl.create(:user) }
end
```

The step for 'I am logged in' will be shared.

## Defining flexible steps

One of the main advantages of Cucumber's regular expression-based step definitions is that you can define steps with parameters, such as:

```ruby
Given /^I am logged in as an? (.+)$/ do |role|
  @current_user = FactoryGirl.create(:user, role: role)
  visit new_session_path

  fill_in 'Username', with: @current_user.username
  fill_in 'Password', with: @current_user.password

  click_button 'Log in'
end
```

This step definition will let you use steps like 'Given I am logged in as an admin' and 'Given I am loged in as a user' with a single step definition.  You can do something similar in SimpleBDD with a little metaprogramming, while being more explicit about what you are defining:

```ruby
['a_user', 'an_admin'].each do |role|
  define_method :"i_am_logged_in_as_#{role}" do
    @current_user = FactoryGirl.create(:user, role: role)
    visit new_session_path

    fill_in 'Username', with: @current_user.username
    fill_in 'Password', with: @current_user.password

    click_button 'Log in'
  end
end

(1..10).each do |num|
  define_method :"there_are_#{num}_comments" do
    num.times { FactoryGirl.create(:comment) }
  end
end
```

Again taking advantage of the class scope of each feature and scenario, you could override respond_to? and  method_missing to do regular expression matching on step definitions:

```ruby
def self.respond_to?(method_sym, include_private = false)
  if method_sym.to_s =~ /^there_are_(\d+)_comments$/
    true
  else
    super
  end
end

def self.method_missing(method_sym, *arguments, &block)
  if method_sym.to_s =~ /^there_are_(\d+)_comments$/
    create_comments($1.to_i)
  else
    super
  end
end
```

I don't recommend going this route, as it can get very complex very quickly, but if you are able to define a large number of useful steps in one shot, it can be appropriate.

## Debugging

When your feature specs are failing and you don't know why, there are two tools that can be very helpful, both of which should be added to your Gemfile:

1) pry.  This very widely used ruby debugger will open up a shell whenever it encounters the line 'binding.pry' in your code.  This works equally well in feature specs, unit tests, and implementation code.
2) launchy.  This gem is specific to feature specs.  In a step definition, you can say 'save_and_open_page' and the page, as currently rendered by capybara-webkit, will be opened in a new tab in your web browser.  This page will be completely unstyled, but it can be inspected to see if you are on the wrong page, if a form field or DOM element isn't named quite like you thought it was, or many of the other common errors that come up in feature specs.

If you are using these tools, it can be helpful to create a step module like this in support/steps/debugging.rb:

```ruby
module Features
  module Steps
    def i_pry
      binding.pry
    end
    
    def i_save_and_open_page
      save_and_open_page
    end
  end
end
```

Then, in your feature specs, you can do something like:

```ruby
feature 'Buggy page' do
  scenario 'I am breaking something' do
    Given 'I view the buggy page'
    And 'I save and open page'
  end
end
```

When the 'I save and open page' step is reached, the page will open in your browser.  You can also use these commands in the middle of a step definition, like:

```ruby
  define_method :"i_am_logged_in_as_a_user" do
    @current_user = FactoryGirl.create(:user)
    visit new_session_path

    fill_in 'Username', with: @current_user.username
    fill_in 'Password', with: @current_user.password
    save_and_open_page
    click_button 'Log in'
  end
end
```

The page that opens up in the browser will be what would be shown right before you click the 'Log in' button, and will have the appropriate fields filled in.

## Alternate Web Drivers

The default web driver that capybara uses is called RackTest.  It can do basic web browsing, but it has no support for stylesheets or JavaScript, both of which are used heavily in modern web applications.  As your application grows, it will almost always be necessary to select a more full-featured web driver.  Instructions for installing these drivers can be found on [capybara's GitHub page](https://github.com/jnicklas/capybara#drivers).

### capybara-webkit

capybara-webkit is a driver that uses the WebKit framework (also used by Safari and Chrome) to render your page and execute capybara commands.  It supports JavaScript to some extent.  It also runs headlessly, which means you don't need access to a graphical interface to use it.  It runs relatively quickly, and is simple to set up in continuous integration environments.  You will need to install the Qt libraries and associated development headers to use it, but that is a strightforward process on MacOS and Linux.  Its primary limitation is that it can't click on links where the link text is an icon.

### Selenium

Selenium uses a full Firefox browser to run your capybara features.  This is good and bad; since it has to load an entire browser, it is much slower than capybara-webkit and can be tricky to use in continuous integration.  However, since it is running on a full-featured browser, there are no missing features.  If your web application runs in FireFox, it is testable in Selenium.  Also, since your tests are running in an actual browser, you can watch them run.
