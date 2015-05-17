# Catchy Title??

In an ideal world, everyone who makes Rails apps would do test-driven development, but many do not do so due to the complexity of setup, the additional time it takes to write tests, and general laziness.  I believe that by providing simple, powerful tools and the guidance in using them, at least the first two factors can be eliminated, and general laziness will become reason TO write tests rather than a reason NOT TO write tests.

What is described here is feature-driven development, which is a natual extension of test-driven and behavior-driven development.  The idea is to start by writing a computer-and-human-readable description of the features of our app, then implement those features step-by-step, unit-testing each component as it is written.  The failing or pending tests tell us what we need to implement next.  When a feature specification and all of its unit tests are passing, you'll know the feature is complete.  Like pretty much every other web application tutorial lately, we're going to build a to-do list.  This is a somewhat trivial example, but once you get into the rhythm of using Simple BDD, you will be able to apply it to more complex projects.

In order to follow this tutorial, you'll need a basic understanding of Rails, and it will help if you've done a bit of testing with RSpec.  The tools used are:

- RSpec, a very widely-used testing framework for Ruby.  (http://rspec.info/)
- Simple BDD, a small frameowrk that greatly simplifies writing feature specs, which are the linchpin of BDD.
- Capybara, a web driver that lets your feature specs act as if they were in a browser. (http://jnicklas.github.io/capybara/)
- FactoryGirl, a replacement for fixtures that makes it easy to create dynamic data for your tests (https://github.com/thoughtbot/factory_girl)

## Basic Setup

- Create a new Rails application.  Make sure you pass the -T flag to rails new to avoid generating the default testing infrastructure.  The current version of Rails at the time of this writing is 4.2.1
- Add the following to your Gemfile and run bundle install:
```ruby
group :test do
  gem 'capybara'
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
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

require 'capybara/rspec'
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

Finally, add the following to your config/application.rb to ensure that Rails generators generate the required testing infrastructure:

``` 
config.generators do |g|
  g.template_engine :erb
  g.test_framework  :rspec, :fixture => true, :views => false
  g.integration_tool :rspec, :fixture => true, :views => true
  g.fixture_replacement :factory_girl, dir: 'spec/factories'
end
```


## Describing Features

A feature spec defines one feature, which is a subset of the functionality of your application.  Each feature has one or more scenarios; a scenario might describe a single aspect of the feature, or a path through the feature.  Each scenario is composed of one more more steps, which describe the user story for the scenario.  Each step begins with one of the following words: Given, When, Then, And, But and is followed by a string explaining the step in human-understandable language.

In order to have ato-do list, users will need to be able to view all items, add new items, check off completed items, and delete items.  A feature spec for the user management could live in spec/features/todo_list_spec.rb and look like this:

```ruby
require 'rails_helper'

feature 'Todo management' do
  scenario 'Adding an item to the list' do
    Given 'I am viewing the list'
    When 'I add a new item'
    Then 'I see the new item'
    And 'It is not completed'
  end

  scenario 'Viewing the list' do
    Given 'There is an item on the list'
    When 'I view the list'
    Then 'I see the item'   
  end

  scenario 'Viewing an empty list' do
    Given 'There are no to-do list entries'
    When 'I view the list'
    Then 'I see that there are no entries'
  end

  scenario 'Completing an item' do
    Given 'There is an item on the list'
    When 'I view the list'
    When 'I complete the item'
    Then 'The item is completed'
  end
end
```

A few things to note about this feature spec:
- It is written in something that closely resembles English.  In a work situation, you'll often have a product manager with a vision of what needs to be developed; by sharing this spec with him or her, you can ensure that you have a mutual understanding of what is being built.
- You could write your steps in any language supported by Ruby, but Simple BDD only supports English for the initial word.  If your code is in Spanish, you'd have to write When "estoy viendo la lista", not Cuando "estoy viendo la lista".
- Each line describes an action that may take many steps to accomplish in the UI.  The idea of feature specs is to describe features, not your UI, and you want to be able to make simple changes to the UI without breaking your feature specs.
- Your feature specs all live under the spec/features/ directory.  You may add subdirectories to this directory, and you may name the files whatever you wish, as long as they end in _spec.rb

Once this file is in place, run your specs.  Since we've defined scenarios and steps but not implemented the steps, you'll get four pending specs like this:

```
  1) Todo management Adding an item to the list
     # i_am_viewing_the_list
     Failure/Error: Given 'I am viewing the list'
     SimpleBdd::StepNotImplemented:
       i_am_viewing_the_list
```

The last line above contains the method you'll need to implement in order for that step to work, i_am_viewing_the_list.  Let's implement that, within the feature block but outside the scenario blocks:

```
  def i_am_viewing_the_list
    visit items_path
  end
```

This step function contains a Capybara command.  visit instructs the virtual browser to go to the specified path.  You can specify the path by relative URL ('/session/new') or using Rails URL helpers, as I've done here.  

If you run this spec, you'll get an error for each step that begins with the 'I am viewing the list' step:

```
1) Todo management Adding an item to the list
     Failure/Error: visit items_path
     NameError:
       undefined local variable or method `items_path' for #<RSpec::ExampleGroups::TodoManagement:0x007f8e84cd5cc0>
```

This tells us the next step in our development: the URL helper is missing, so add a route!  Add the following to config/routes.rb:

```ruby
resources :items
```

Re-running the spec will give you a new error for the tests that were failing before:

```
1) Todo management Adding an item to the list
     Failure/Error: visit items_path
     ActionController::RoutingError:
       uninitialized constant ItemsController
```

It's time to build a controller!  While feature specs are intended to be very high-level, controllers and models are unit-tested, so we want to examine every case we can think of.  Controller specs live under spec/controllers/ and are named by the controller they are testing.  Here's spec/controllers/items_controller_spec.rb, which tests the :index action:

```ruby
require 'rails_helper'

describe ItemsController do
  describe '#index' do
    before do
      get :index
    end

    it 'renders the index' do
      expect(response).to render_template(:index)
    end
  end
end
```

If you run this spec, it will fail for the same reason our feature spec failed:  We don't have a UsersController yet.  Let's add one with a new action in app/controllers/users_controller.rb:

```ruby
class ItemsController < ApplicationController
  def index
  end
end
```

If you run your specs again (which you should do after implementing anything), you'll see a new error:

```
1) ItemsController#index renders the index
     Failure/Error: get :index
     ActionView::MissingTemplate:
       Missing template items/index, application/index with {:locale=>[:en], :formats=>[:html], :variants=>[], :handlers=>[:erb, :builder, :raw, :ruby, :jbuilder]}.
```

Like before, RSpec is telling you what to do next:  Make a view!  The following goes in app/views/items/index.html.erb, and should look familiar to anyone who has done a Rails tutorial:

```erb
<div id="item-list">
  <% @items.each do |item| %>
    <div id="item-<%= item.id %>" %>
      <%= item.text %> <%= item.completed ? "Completed" : "Not Completed" %>
    </div>
  <% end %>
</div>
```

Note that there are some CSS ids that don't seem necessary yet; they will assist with testing later.  Running specs fail now because we haven't defined @items:

```
1) Todo management Adding an item to the list
     Failure/Error: visit items_path
     ActionView::Template::Error:
       undefined method `each' for nil:NilClass
```

So let's add that to the index action in ItemsController:

```ruby
class ItemsController < ApplicationController
  def index
    @items = Item.all
  end
end
```

That fails because we don't have an Item model:

```
1) ItemsController#index renders the index
     Failure/Error: get :index
     NameError:
       uninitialized constant ItemsController::Item
```

So let's make one using the Rails generators:

```
rails g model item text:string completed:boolean
```

This will generate a model spec; we can leave that pending now, as the Item model has no functionality.  Run your migrations and run rspec again.  Our first step in the feature specs now completes sucessfully, so we're back to pending!

```
1) Todo management Adding an item to the list
     # i_add_a_new_item
     Failure/Error: When 'I add a new item'
     SimpleBdd::StepNotImplemented:
       i_add_a_new_item
```

We need to implement the step where a new item is added.  Describe how to do it by adding the following to spec/features/todo_list_spec.rb:

```ruby
  let(:item_text) { Faker::Lorem.sentence }

  def i_add_a_new_item
    within('#new-item') do
      fill_in 'Text', with: item_text
      click_button 'Save'
    end
  end
```

This step has a couple of Capybara commands that deserve some explaination:
- within takes CSS selector that lets your narrow down on the page where you want to perform an action or check for content.  While at present the page doesn't contain much, it is good practice to narrow your searches down as much as possible.
- fill_in and click_button do what's described on the tin; fill_in fills a text box with the given text, and click_button hits the submit button (or whichever button you specify).

Also, we're going to use a let for the actual item, because we need to check later that the item appears on the page.  Lets are only evaluated once per feature.

This step will fail because we haven't added a CSS id #new-item yet:

```
1) Todo management Adding an item to the list
     Failure/Error: within('#new-item') do
     Capybara::ElementNotFound:
       Unable to find css "#new-item"
```

Let's go ahead and write the markup for the new item form, adding the following to the bottom of app/views/items/index.html.erb:

```erb
<div id="new-item" %>
  <%= form_for :item do |f| %>
    <%= f.label :text %>:
    <%= f.text_field :text %>
    <%= f.submit %>
  <% end %>
</div>
```

This gives us a new error, once again indicating the next step in our development:

```
1) Todo management Adding an item to the list
     Failure/Error: click_button 'Save'
     AbstractController::ActionNotFound:
       The action 'create' could not be found for ItemsController
```

Let's write a spec for the create action before we write it, in spec/controllers/items_controller_spec.rb:

```ruby
  describe '#create' do
    before do
      allow(Item).to receive(:create)
      post :create, { item: { text: Faker::Lorem.sentence } }
    end

    it 'creates an item' do
      expect(Item).to have_received(:create)
    end

    it 'redirects back to the index' do
      expect(response).to redirect_to items_path
    end
  end
```

Then we can write the action.  Since it's pretty simple, we'll do the whole thing in one shot, in app/controllers/items_controller.rb:

```ruby
  def create
    Item.create(item_params)
    redirect_to items_path
  end
  
  private

  def item_params
    params.require(:item).permit(:text)
  end
```

If we run rspec again, we'll see that the feature step we were working on passes, and we can continue to the next one:

```
  1) Todo management Adding an item to the list
     # i_see_the_item
     Failure/Error: Then 'I see the new item'
     SimpleBdd::StepNotImplemented:
       i_see_the_new_item
```

Now, we can check that the item exists:

```ruby
  def i_see_the_new_item
    within('#item-list') do
      expect(page).to have_content item_text
    end
  end
```

Run your specs again, and you'll see that we've already done this, so the step passes.  But the next step doesn't:

```
1) Todo management Adding an item to the list
     # it_is_not_completed
     Failure/Error: And 'It is not completed'
     SimpleBdd::StepNotImplemented:
       it_is_not_completed
```

We need some way to mark whether the item has been completed or not.  Add a test as to whether the item is completed:

```ruby
  def it_is_not_completed
    within('#item-list') do
      expect(page).to have_text "Not Completed"
    end
  end
```

This will fail because the expected text was not found.  Let's add it to the view in app/views/items/index.html.erb:

```erb
<div id="item-list">
  <% @items.each do |item| %>
    <div id="item-<%= item.id %>" %>
      <%= item.text %> <%= completed?(item) %>
    </div>
  <% end %>
</div>
```

And the completed? helper in app/helpers/items_helper.rb:

```ruby
module ItemsHelper
  def completed?(item)
    if item.completed
      "Completed"
    else
      "Not Completed"
    end
  end
end
```

You have your first passing feature spec!  The next pending spec is a little different than the previous oneas, as it only requires that we set up the criteria for the test:

```
1) Todo management Viewing the list
     # there_is_an_item_on_the_list
     Failure/Error: Given 'There is an item on the list'
     SimpleBdd::StepNotImplemented:
       there_is_an_item_on_the_list
```

To make this one pass, use FactoryGirl to create an item.  The rails generator created a factory when we generated our model, which we can find in spec/factories/item_factory.rb; the default factory is ok, but for our purposes it's better to add some randomness using Faker:

```ruby
FactoryGirl.define do
  factory :item do
    text { Faker::Lorem.sentence }
    completed false
  end
end
```

So add this to the feature spec:

```ruby
  let(:item) { FactoryGirl.create(:item) }
  def there_is_an_item_on_the_list
    item
  end
```

The next step is identical to another step we've already defined, just worded differently:

```
1) Todo management Viewing the list
     # i_view_the_list
     Failure/Error: When 'I view the list'
     SimpleBdd::StepNotImplemented:
       i_view_the_list
```

So, let's add a method alias:

```ruby
  def i_am_viewing_the_list
    visit items_path
  end
  alias_method :i_view_the_list, :i_am_viewing_the_list
```

And we get another pending step:

```
1) Todo management Viewing the list
     # i_see_the_item
     Failure/Error: Then 'I see the item'
     SimpleBdd::StepNotImplemented:
       i_see_the_item
```

This is different from i_see_the_new_item, because we're looking for the item generated by FactoryGirl in the let(:item).  To implement the step, we can do a similar check to the one for i_see_the_new_item, but because we have an item id, we can search in the actual line item:

```ruby
  def i_see_the_item
    within("#item-#{item.id}") do
      expect(page).to have_text item.text
    end
  end
```

And we have another passing feature spec!  Now we can finish up the third one:

```
  1) Todo management Viewing an empty list
     # there_are_no_to_do_list_entries
     Failure/Error: Given 'There are no to-do list entries'
     SimpleBdd::StepNotImplemented:
       there_are_no_to_do_list_entries
```

This is more of a destructive step than a constructive step:

```ruby
  def there_are_no_to_do_list_entries
    Item.destroy_all
  end
```

The next step is looking for a blank state:

```
1) Todo management Viewing an empty list
     # i_see_that_there_are_no_entries
     Failure/Error: Then 'I see that there are no entries'
     SimpleBdd::StepNotImplemented:
       i_see_that_there_are_no_entries
```

So let's add the step:

```ruby
  def i_see_that_there_are_no_entries
    within('#item-list') do
      expect(page).to have_text "No items in list"
    end
  end
```

This will fail because we haven't implemented the blank state yet:

```
1) Todo management Viewing an empty list
     Failure/Error: expect(page).to have_text "No items in list"
       expected to find text "No items in list" in ""
```

Let's add one in the view:

```erb
<div id="item-list">
  <% if @items.size > 0 %>
    <% @items.each do |item| %>
      <div id="item-<%= item.id %>" %>
        <%= item.text %> <%= completed?(item) %>
      </div>
    <% end %>
   <% else %>
     No items in list
   <% end %>
</div>
```

Only one feature spec left to go!  

```
1) Todo management Completing an item
     # i_complete_the_item
     Failure/Error: When 'I complete the item'
     SimpleBdd::StepNotImplemented:
       i_complete_the_item
```

We need a step to complete the item.  For now, let's just make it a link to click.  In spec/features/todo_list_spec.rb:

```ruby
  def i_complete_the_item
    within("#item-#{item.id}") do
      click_link 'Mark Completed'
    end
  end
```

And in app/views/items/index.html.erb:

```erb
 <div id="item-<%= item.id %>" %>
    <%= item.text %> <%= completed?(item) %>
    <%= link_to "Mark Completed", mark_completed_item_path(item) %>
  </div>
```

You probably know why this is going to fail:  We haven't defined the approprite route.  Let's do that:

```ruby
  resources :items do
    get :mark_completed, on: :member
  end
```

And again, you know why the spec is going to fail: No action for mark_completed.  Let's write a spec for that in spec/controllers/items_controller_spec.rb:

```ruby
  describe '#mark_completed' do
    let(:item) { double(:item) }
    let(:item_id) { rand(1000) }

    before do
      allow(Item).to receive(:find).with(item_id.to_s) { item }
      allow(item).to receive(:update_attributes) { true }
      get :mark_completed, id: item_id
    end

    it 'marks the item completed' do
      expect(item).to have_received(:update_attributes).with(completed: true)
    end

    it 'redirects back to the index' do
      expect(response).to redirect_to items_path
    end
  end
```

You'll notice that this spec creates test doubles and stubs all of the action on the item model.  The idea behind this is that your controller spec should only test what is happening in the controller.  In your controller, stub what you expect the Item model to do, and in the spec on the Item model, you can make sure that what you stubbed in the controller is what is actually happening.

You may be wondering, if that's true, why haven't we written any model specs on Item yet??  The answer is that there's no reason to; everything we're doing in Item is straight out of ActiveRecord, which is very well-tested.  If, at a later point, we decide to add something to the Item model, like validations or callbacks, those will need to be tested.

Let's write an action in app/controllers/items_controller.rb to make the controller spec pass:

```ruby
  def mark_completed
    @item = Item.find(params[:id])
    @item.update_attributes(completed: true)
    redirect_to items_path
  end
```

Finally, we have one last feature step to make pass:

```
1) Todo management Completing an item
     # it_is_completed
     Failure/Error: Then 'The item is completed'
     SimpleBdd::StepNotImplemented:
       the_item_is_completed
```

All we need to do is add the step:

```ruby
  def the_item_is_completed
    within("#item-#{item.id}") do
      expect(page).to have_text 'Completed'
      expect(page).to_not have_link 'Mark Completed'
    end
  end
```

And make the view match the step:

```erb
<div id="item-<%= item.id %>" %>
  <%= item.text %> <%= completed?(item) %>
  <% unless item.completed %>
    <%= link_to "Mark Completed", mark_completed_item_path(item) %>
  <% end %>
</div>
```

With that, you've completed your feature.  The only remaining pending spec is the model; if you are done with the model, you can go ahead and remove the pending from that model and have a passing set of specs.  But you're probably not done.  You might want to be able to uncomplete completed items.  You might want to delete items from the list.  You might want to have a user authentication system and allow each user to have a separate list.  You can build anything you'd normally build into a web application using this style. The abstracted process is:

1. Write a feature spec
2. Implement the next pending step
3. Fix the test failures caused by the step using models, controllers and views
4. Repeat (2) and (3) until the feature spec passes

The idea is to let RSpec tell you what to do next.  As you're working, don't be afraid to refactor feature specs as you find better ways to implement your features, or to clean up any code that is associated with passing tests.  When you've finished, you will have an application that is well-tested, well-documented, and can easily be extended. 
Note that the application is completely unstyled; I haven't even told you to look at it in a web browser.  When you do so, you'll probably be horrified at what it looks like, but it works exactly like you expect it to!  Since you have good test coverage, you can start rearranging things on the page, adding CSS, and tweaking things without worrying too much about breaking things; if your specs start to fail, you can adapt your code and your tests to match the new desired behavior.

Almost all of the tools here are widely used and have excellent documentation, linked to at the top of this post.  If you need to unit-test something, chances are there's a clean way to do it in RSpec, and if there isn't, you might need to adjust your approach to the problem you're solving.  And if you can perform an action in a web browser, you can perform the same action in capybara; it can even use JavaScript by firing up an actual instance of FireFox on your computer.  This can be slow, but it's a great way to be sure everything works the way you want it to.

Happy featuring!
