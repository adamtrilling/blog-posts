# Feature Driven Development

In an ideal world, everyone who makes Rails apps would do test-driven development. However, many do not because of the complexity of setup, the additional time it takes to write tests, and general laziness. I believe that by providing simple, powerful tools and techniques, and the guidance in using them, at least the first two factors can be eliminated. Then general laziness will become reason TO write tests rather than a reason NOT TO.

The technique is Feature Driven Development, the tools are SimpleBDD and RSpec, and the guidance is this series of three blog posts.

## The Stack
- RSpec, a very widely used testing framework for Ruby.  (http://rspec.info/)
- Simple BDD, a small framework that greatly simplifies writing feature specs, which are the linchpin of BDD. (https://github.com/robb1e/simple_bdd)
- Capybara, a web driver that lets your feature specs act as if they were in a browser. (http://jnicklas.github.io/capybara/)
- FactoryGirl, a replacement for fixtures that makes it easy to create dynamic data for your tests. (https://github.com/thoughtbot/factory_girl)

## The Process Of Developing A Feature

1. Describe your feature in terms of steps.  SimpleBDD allows you to do this in a language closely resembling plain English.
2. Implement the first pending step definition.
3. Run the feature spec.  It will fail, and the error message will tell you what you need to do to make it pass. For example, if a route is missing, write the route.  If a controller or model is missing, write the controller or model (and any associated unit tests).  If there's a missing view, write it.  If there's a bug in your code, fix it.
4. Repeat steps 2 and 3 until your feature spec is passing.  When your feature spec is passing, your feature is complete.

The beauty of this process is twofold.  First, it avoids the coder's block that many developers face when starting on a large feature.  Instead of having to worry about all of the implementation details of your feature before you write any code, you can write the feature steps and worry about the details as you get to them.  Second, as you're working on your feature, RSpec is always telling you what you need to do next.

## Anatomy Of A Feature Spec
A feature spec defines one feature, which is a subset of the functionality of your application. Each feature has one or more scenarios. A scenario might describe a single aspect of the feature, or a path through the feature. Each scenario is composed of one more more steps, which describe the user story for the scenario. Each step begins with one of the following words: Given, When, Then, And, But and is followed by a string explaining the step in human-understandable language.  The string part of the step is converted into a method name, and that method definition will describe how the step should proceed.

What follows is a part-by-part description of the sample code (spec/features/todo_list_spec.rb).  In the next part of this series, we will examine the entire spec and use it to build out the feature.

```ruby
require 'rails_helper'
```

SimpleBDD feature specs are implemented using RSpec's feature spec functionality, so we include rails_helper like any other spec file.

```ruby
feature 'Todo management' do
  scenario 'Adding an item to the list' do
    Given 'I am viewing the list'
    When 'I add a new item'
    Then 'I see the new item'
    And 'It is not completed'
  end
```

A feature is composed of one or more scenarios, and each scenario is composed of one or more steps.  The scenarios read sort of like plain English.

```ruby
  def i_am_viewing_the_list
    visit items_path
  end
  alias_method :i_view_the_list, :i_am_viewing_the_list
```
Each step matches to one method definition.  The method body contains a Capybara function to tell Capybara's virtual browser to type the items_path into the URL bar.  You can use all of your Rails path helpers, or a URL relative to the root path.  If you wish to have a step that does the same thing with slightly different wording, you can use alias_method to duplicate the step.

```ruby
  let(:item_text) { Faker::Lorem.sentence }
```

You can use `let` just like in other RSpec specs.  Every scenario is run within its own class context, so you can use instance variables to share data between steps, but `let` definitions are easier to keep track of when dealing with shared step definitions.

```ruby
  def i_add_a_new_item
    within('#new-item') do
      fill_in 'Text', with: item_text
      click_button 'Save'
    end
  end
```

Capybara can fill out forms for you, as well as submit them.  You can specify form elements by label or HTML id, and you can narrow down where on the page the browser looks for the form elements using within.  Filling out and submitting a form this way tests your controllers and views in one succinct process.

```ruby
  def i_see_the_new_item
    within('#item-list') do
      expect(page).to have_content item_text
    end
  end
end
```

Finally, you can use Capybara's matchers to make assertions about the page content at any point in your scenario.  With these tools, you can automatically test every path through your application, saving many hours of work that you (or your QA team) would have spent clicking and clicking and clicking.

Stay tuned for Part 2, which will lead you through the full process of setting up SimpleBDD and developing a feature with it.
