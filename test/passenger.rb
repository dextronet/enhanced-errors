class Passenger < Struct.new(:name)
  
  include ActiveModel::Validations
  include ActiveModel::Serialization
  
  validates_presence_of :name
  
end