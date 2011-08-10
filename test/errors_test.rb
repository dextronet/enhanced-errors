require File.dirname(__FILE__) + '/test_helper'

class ErrorsTest < Test::Unit::TestCase

  def test_full_messages_original_behavior
    car = Car.new
    car.wheels = 2
    car.steering_wheel = nil
    car.full_tank = false
    car.valid?
    
    assert_equal 3, car.errors.full_messages.size
    # return an array of three string error messages
    assert car.errors.full_messages.all? { |m| m.is_a?(String) }
  end
  
  def test_with_type_option
    car = Car.new
    car.wheels = 2
    car.steering_wheel = nil
    car.full_tank = false
    car.valid?
    
    full_messages = car.errors.full_messages(:with_type => true)
    
    assert_equal 3, full_messages.size
    assert full_messages.all? { |m| m.is_a?(EnhancedErrors::MessageWithType) }
  end
  
  def test_full_messages_block
    car = Car.new
    car.wheels = 2
    car.steering_wheel = nil
    car.full_tank = false
    car.valid?
    
    block_attributes = []
    car.errors.full_messages do |attribute, message|
      block_attributes << attribute
    end
    
    assert_equal [:wheels, :steering_wheel, :full_tank], block_attributes
  end
  
  def test_full_message_option
    car = Car.new
    car.wheels = 4
    car.steering_wheel = true
    car.full_tank = false
    car.valid?
    
    # we defined the :full_message => true option in the validates_acceptance_of in the Car model
    assert_equal "You can't drive very long with a half empty tank.", car.errors.full_messages.first
    
    car.errors.add :wheels, :invalid, :message => "Wheels are invalid."
    assert_equal "Wheels Wheels are invalid.", car.errors.full_messages.second
    
    car.errors.add :wheels, :blank, :message => "Wheels are blank.", :full_message => true
    assert_equal "Wheels are blank.", car.errors.full_messages.third
  end
  
  def test_xml_serialization
    car = Car.new
    car.wheels = nil
    car.steering_wheel = nil
    car.full_tank = false
    car.valid?
    
    car.errors[:passengers] = "have to be in the car."
    
    h = ActiveSupport::XmlMini.parse(car.errors.to_xml)
    
    # Expected xml:
    #
    # <?xml version="1.0" encoding="UTF-8"?>
    # <errors>
    #   <error on="wheels" type="blank">Wheels can't be blank</error>
    #   <error on="wheels" type="invalid">Wheels is invalid</error>
    #   <error on="wheels" type="inclusion">Wheels is not included in the list</error>
    #   <error on="steering_wheel" type="blank">Steering wheel can't be blank</error>
    #   <error on="full_tank" type="accepted">You can't drive very long with a half empty tank.</error>
    #   <error on="passengers">Passengers have to be in the car.</error>
    # </errors>
    
    # Expected hash:
    #
    # { 
    #   "errors" => { 
    #     "error" => [
    #       { "on" => "wheels",         "type" => "blank",     "__content__" => "Wheels can't be blank" }, 
    #       { "on" => "wheels",         "type" => "invalid",   "__content__" => "Wheels is invalid" }, 
    #       { "on" => "wheels",         "type" => "inclusion", "__content__" => "Wheels is not included in the list" }, 
    #       { "on" => "steering_wheel", "type" => "blank",     "__content__" => "Steering wheel can't be blank" }, 
    #       { "on" => "full_tank",      "type" => "accepted",  "__content__" => "You can't drive very long with a half empty tank." }, 
    #       { "on" => "passengers",                            "__content__" => "Passengers have to be in the car." }
    #     ]
    #   }
    # }
    
    assert h["errors"].present?
    assert h["errors"]["error"].present?
    assert_equal 6, h["errors"]["error"].size
    
    assert_equal "wheels", h["errors"]["error"].at(0)["on"]
    assert_equal "wheels", h["errors"]["error"].at(1)["on"]
    assert_equal "wheels", h["errors"]["error"].at(2)["on"]
    assert_equal "steering_wheel", h["errors"]["error"].at(3)["on"]
    assert_equal "full_tank", h["errors"]["error"].at(4)["on"]
    assert_equal "passengers", h["errors"]["error"].at(5)["on"]
    
    assert_equal "blank", h["errors"]["error"].at(0)["type"]
    assert_equal "invalid", h["errors"]["error"].at(1)["type"]
    assert_equal "inclusion", h["errors"]["error"].at(2)["type"]
    assert_equal "blank", h["errors"]["error"].at(3)["type"]
    assert_equal "accepted", h["errors"]["error"].at(4)["type"]
    assert !h["errors"]["error"].at(5).key?("type")
    
    assert h["errors"]["error"].all? { |h| h["__content__"].present? }
  end
  
#  def test_association_validation
#    car = Car.new
#    car.passengers.build
#    car.wheels = 4
#    car.steering_wheel = true
#    car.full_tank = true
#    
#    assert !car.valid?
#    
#    puts car.errors.to_xml
#    
#    assert message = car.errors[:passengers]
#    assert message.is_a?(EnhancedErrors::MessageWithType)
#    assert_equal "", message.type
#  end

end