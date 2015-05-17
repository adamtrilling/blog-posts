module ItemsHelper
  def completed?(item)
    if item.completed
      "Completed"
    else
      "Not Completed"
    end
  end
end
