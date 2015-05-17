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
end
