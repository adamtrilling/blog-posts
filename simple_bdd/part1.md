# Feature Driven Development

In an ideal world, everyone who makes Rails apps would do test-driven development, but many do not do so due to the complexity of setup, the additional time it takes to write tests, and general laziness. I believe that by providing simple, powerful tools and techniques, and the guidance in using them, at least the first two factors can be eliminated, and general laziness will become reason TO write tests rather than a reason NOT TO write tests. The technique is Feature Driven Development, the tools are SimpleBDD and RSpec, and the guidence is this blog post.

## The Process Of Developing A Feature

1. Describe your feature in terms of steps.  SimpleBDD allows you to do this in a language closely resembling plain English.
2. Implement each step in order.
3. If the step fails because a controller is necessary, write unit specs for the controller, then write the controller. If the step fails because a model is necessary, write unit specs for the model, then write the model. Once the controller and model specs are passing, continue with your feature spec.
4. When your feature spec is passing, your feature is complete.

## The Stack
- RSpec, a very widely-used testing framework for Ruby.  (http://rspec.info/)
- Simple BDD, a small frameowrk that greatly simplifies writing feature specs, which are the linchpin of BDD. (https://github.com/robb1e/simple_bdd)
- Capybara, a web driver that lets your feature specs act as if they were in a browser. (http://jnicklas.github.io/capybara/)
- FactoryGirl, a replacement for fixtures that makes it easy to create dynamic data for your tests (https://github.com/thoughtbot/factory_girl)

## Why Simple BDD instead of Cucumber?
Cucumber is the tool most people think of when mentioning Behavior-Driven Development. Cucumber is an excellent tool for this, and BDD using Cucumber follows the same process as BDD using SimpleBDD.  There are two main differences between SimpleBDD and Cucumber:
- In Cucumber, step definitions are matched to steps using regular expressions. In SimpleBDD, step defintions are translated into method names.  The Cucumber approach provides more power and flexibility in small projects, because 
