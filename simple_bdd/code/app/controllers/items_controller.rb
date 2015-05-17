class ItemsController < ApplicationController
  def index
    @items = Item.all
  end

  def create
    Item.create(item_params)
    redirect_to items_path
  end
 
  def mark_completed
    @item = Item.find(params[:id])
    @item.update_attributes(completed: true)
    redirect_to items_path
  end

  private

  def item_params
    params.require(:item).permit(:text)
  end 
end
