require 'pp'

RSpec::Matchers.define :allow_value do |value|
  chain :for do |attribute|
    @attribute = attribute
  end

  match do |model|
    model.public_send("#{@attribute}=", value)
    model.valid?
  end

  failure_message do |model|
    <<~MSG
      expected #{model.class} to be valid with #{value.inspect} for #{@attribute}
      but got errors: #{PP.pp(model.errors, '')}
    MSG
  end

  failure_message_when_negated do |model|
    "expected #{model.class} not to be valid with #{value.inspect} for #{@attribute}"
  end

  description do
    "allow value #{value.inspect} for #{@attribute}"
  end
end
