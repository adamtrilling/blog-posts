# Feature Driven Development

In an ideal world, everyone who makes Rails apps would do test-driven development, but many do not do so due to the complexity of setup, the additional time it takes to write tests, and general laziness. I believe that by providing simple, powerful tools and techniques, and the guidance in using them, at least the first two factors can be eliminated, and general laziness will become reason TO write tests rather than a reason NOT TO write tests. The technique is Feature Driven Development, the tools are SimpleBDD and RSpec, and the guidence is this series of blog posts.

## The Stack
- RSpec, a very widely-used testing framework for Ruby.  (http://rspec.info/)
- Simple BDD, a small frameowrk that greatly simplifies writing feature specs, which are the linchpin of BDD. (https://github.com/robb1e/simple_bdd)
- Capybara, a web driver that lets your feature specs act as if they were in a browser. (http://jnicklas.github.io/capybara/)
- FactoryGirl, a replacement for fixtures that makes it easy to create dynamic data for your tests (https://github.com/thoughtbot/factory_girl)

## The Process Of Developing A Feature

1. Describe your feature in terms of steps.  SimpleBDD allows you to do this in a language closely resembling plain English.
2. Implement the first pending step definition.
3. If the step fails because a controller is necessary, write unit specs for the controller, then write the controller. If the step fails because a model is necessary, write unit specs for the model, then write the model. Once the controller and model specs are passing, continue working on the step definition until it passes.
4. Repeat steps 2 and 3 until your feature spec is passing.  When your feature spec is passing, your feature is complete.

The beauty of this process is twofold.  First, it avoids the coders block that many developers face when starting on a large feature.  Instead of having to worry about all of the implementation details of your feature before you write any code, you can write the feature steps and worry about the details as you get to them.  Second, as you're working on your feature, RSpec is always telling you what you need to do next

## Why Simple BDD instead of Cucumber?
Cucumber is the tool most people think of when mentioning Behavior-Driven Development. Cucumber is an excellent tool for this, and BDD using Cucumber follows the same process as BDD using SimpleBDD.  There are three main differences between SimpleBDD and Cucumber:
- In Cucumber, step definitions are matched to steps using regular expressions. In SimpleBDD, step defintions are translated into method names.
- In Cucumber, step definitions are global.  In SimpleBDD, features and scenarios are contained within their own class context.
- Cucumber is separate from RSpec, and your features and step definitions live outside the spec/ directory in your application.  SimpleBDD lives alongside RSpec, putting its files in spec/features, and the feature tests are run by default when you run RSpec.

The upshot of the design differences is that SimpleBDD encourages you to isolate each feature its step definitions, whereas Cucumber encourages you to share.  In small projects, Cucumber tends to be simpler, but in larger projects, step definitions tend to be spread across many files, making it difficult to figure out what you have already defined.  While both Cucumber and SimpleBDD use instance variables to share context across step definitions, large Cucumber projects tend to cause confusion about which instance variables are defined and what they mean unless you are quite careful about organizing your steps.  Since SimpleBDD makes you take specific measures to share steps across features, it's easier to keep track of these shared steps and what they define.  The close integration between SimpleBDD and RSpec is a matter of convenience.

Stay tuned for Part 2, which will lead you through the process of setting up SimpleBDD and developing a feature with it.
