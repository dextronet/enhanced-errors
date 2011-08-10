module EnhancedErrors
      
  def self.included(base)
    base.class_eval do
      include EnhancedErrors::InstanceMethods
      alias_method_chain :generate_message, :type
      alias_method_chain :full_messages, :type
      alias_method_chain :to_xml, :type
    end
  end
  
  class MessageWithType < Struct.new(:content, :type, :full_message)
    
    alias_method :full_message?, :full_message
    
    def self.wrap(object)
      if object.is_a? MessageWithType
        # we do not want to modify the original message content
        MessageWithType.new(object.content, object.type, object.full_message?)
      else
        MessageWithType.new(object)
      end
    end
    
    def to_s
      content
    end
    
    def translate!(translated_message)
      unless full_message?
        self.full_message = true
        self.content = translated_message
      end
      self
    end
    
    def empty?
      false
    end
    
  end
  
  module InstanceMethods
    
    def generate_message_with_type(attribute, type = :invalid, options = {})
      MessageWithType.new(generate_message_without_type(attribute, type, options), 
        type, options.delete(:full_message))
    end
    
    def full_messages_with_type(options = {})
      with_type = options.delete(:with_type)
      full_messages = []

      each do |attribute, messages|
        messages = Array.wrap(messages)
        next if messages.empty?

        if attribute == :base
          messages.each do |m| 
            full_messages << (with_type ? MessageWithType.wrap(m) : m.to_s)
            yield attribute, full_messages.last if block_given?
          end
        else
          attr_name = attribute.to_s.gsub('.', '_').humanize
          attr_name = @base.class.human_attribute_name(attribute, :default => attr_name)
          options = { :default => "%{attribute} %{message}", :attribute => attr_name }

          messages.each do |m|
            full_message = I18n.t(:"errors.format", options.merge(:message => m))
            full_messages << (
              with_type ? MessageWithType.wrap(m).translate!(full_message) : 
              (MessageWithType.wrap(m).full_message? ? m.to_s : full_message)
            )
            yield attribute, full_messages.last if block_given?
          end
        end
      end

      full_messages
    end
    
    def to_xml_with_type(options = {})
      options[:root]    ||= "errors"
      options[:indent]  ||= 2
      options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

      options[:builder].instruct! unless options.delete(:skip_instruct)
      options[:builder].__send__(:method_missing, options[:root]) do |e|
        full_messages(:with_type => true) do |attribute, message|
          attrs = { :on => attribute }
          attrs.merge!(:type => message.type) if message.is_a?(MessageWithType) && message.type
          options[:builder].__send__(:method_missing, options[:root].singularize, message.to_s, attrs)
        end
      end
    end
    
  end
      
end