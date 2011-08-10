$:.unshift "#{File.dirname(__FILE__)}/lib" 
require 'enhanced_errors'
ActiveModel::Errors.send :include, EnhancedErrors