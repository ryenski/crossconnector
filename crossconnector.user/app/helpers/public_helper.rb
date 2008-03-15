module PublicHelper  
  
  def about?
    return true if @homebase.profile or @homebase.profile_extended
    return true if @homebase.address1 or @homebase.address2 or @homebase.city or @homebase.state or @homebase.country
    return true if @homebase.phone
    return true if @homebase.website
    false
  end
  
end
