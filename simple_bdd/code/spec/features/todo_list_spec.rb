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

  def i_am_viewing_the_list
    visit items_path
  end
  alias_method :i_view_the_list, :i_am_viewing_the_list

  let(:item_text) { Faker::Lorem.sentence }

  def i_add_a_new_item
    within('#new-item') do
      fill_in 'Text', with: item_text
      click_button 'Save'
    end
  end

  def i_see_the_new_item
    within('#item-list') do
      expect(page).to have_content item_text
    end
  end

  def it_is_not_completed
    within('#item-list') do
      expect(page).to have_text "Not Completed"
    end
  end

  let(:item) { FactoryGirl.create(:item) }
  def there_is_an_item_on_the_list
    item
  end
 
  def i_see_the_item
    within("#item-#{item.id}") do
      expect(page).to have_text item.text
    end
  end

  def there_are_no_to_do_list_entries
    Item.destroy_all
  end

  def i_see_that_there_are_no_entries
    within('#item-list') do
      expect(page).to have_text "No items in list"
    end
  end

  def i_complete_the_item
    within("#item-#{item.id}") do
      click_link 'Mark Completed'
    end
  end

  def the_item_is_completed
    within("#item-#{item.id}") do
      expect(page).to have_text 'Completed'
      expect(page).to_not have_link 'Mark Completed'
    end
  end
end
