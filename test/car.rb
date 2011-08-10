class Car < Struct.new(:wheels, :steering_wheel, :full_tank, :passengers)
  
  include ActiveModel::Validations
  include ActiveModel::Serialization
  
  validates_presence_of :wheels
  validates_format_of :wheels, :with => /\d/
  validates_inclusion_of :wheels, :in => 4..10
  validates_presence_of :steering_wheel
  validates_acceptance_of :full_tank, :message => "You can't drive very long with a half empty tank.", :full_message => true
  
end