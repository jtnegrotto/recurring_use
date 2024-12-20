require 'date'

module Model
  class ValidationError < StandardError
    attr_reader :model

    def initialize(model)
      super("Validation failed for #{model.class}")
      @model = model
    end
  end

  def initialize(attributes = {})
    attributes.each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def valid?
    reset_errors
    validate
    errors.empty?
  end

  def validate!
    valid? or raise ValidationError.new(self)
  end

  def validate
    raise NotImplementedError
  end

  def errors
    @errors || reset_errors
  end

  def add_error(attribute, message)
    @errors[attribute] << message
  end

  def reset_errors
    @errors = Hash.new { |hash, key| hash[key] = [] }
  end
end

class RecurringUse
  include Model

  attr_accessor :amount, :start_date, :end_date, :period, :weekday

  PERIODS = %i[daily weekly]
  WEEKDAYS = %i[sunday monday tuesday wednesday thursday friday saturday]

  def validate
    validate_amount
    validate_start_date
    validate_end_date
    validate_period
    validate_weekday
  end

  def daily?
    period == :daily
  end

  def weekly?
    period == :weekly
  end

  def each_use(from_date = Date.today)
    return to_enum(:each_use, from_date).lazy unless block_given?

    each_date(from_date) do |date|
      yield date, amount
    end
  end

  def each_date(from_date = Date.today)
    return to_enum(:each_date, from_date).lazy unless block_given?

    current_date = from_date
    while (next_date = next_date(current_date))
      yield next_date
      current_date = next_date + 1
    end
  end

  def next_date(from_date = Date.today)
    raise ArgumentError, 'from_date must be a date' unless from_date.is_a?(Date)
    validate!

    effective_start_date = [start_date, from_date].max
    next_use_date =
      case period
      when :daily
        effective_start_date
      when :weekly
        weekday_index = WEEKDAYS.index(weekday)
        weekday_offset = (weekday_index - effective_start_date.wday) % 7
        effective_start_date + weekday_offset
      else
        raise NotImplementedError, "period #{period} not implemented"
      end
    next_use_date if end_date.nil? || end_date >= next_use_date
  end

  private

  def validate_amount
    if !amount.is_a?(Integer)
      add_error(:amount, 'must be an integer')
    elsif amount.negative?
      add_error(:amount, 'must not be negative')
    end
  end

  def validate_start_date
    add_error(:start_date, 'must be a date') unless start_date.is_a?(Date)
  end

  def validate_end_date
    return if end_date.nil?

    if !end_date.is_a?(Date)
      add_error(:end_date, 'must be a date')
    elsif start_date.is_a?(Date) && end_date < start_date
      add_error(:end_date, 'cannot be before start_date')
    end
  end

  def validate_period
    add_error(:period, 'is not a valid period') unless PERIODS.include?(period)
  end

  def validate_weekday
    if weekly? && weekday.nil?
      add_error(:weekday, 'must be present when period is weekly')
    elsif weekday && !WEEKDAYS.include?(weekday)
      add_error(:weekday, 'is not a valid weekday')
    end
  end
end

class InventoryItem
  include Model

  attr_accessor :amount, :recurring_uses

  def recurring_uses
    @recurring_uses ||= []
  end

  def validate
    validate_amount
  end

  def each_use(from_date = Date.today)
    return to_enum(:each_use, from_date).lazy unless block_given?

    queue = []
    enqueue = ->(enumerator) {
      begin
        queue << [enumerator.next, enumerator]
        queue.sort_by!(&:first)
      rescue StopIteration; end
    }

    recurring_uses.each do |recurring_use|
      enqueue[recurring_use.each_use(from_date)]
    end

    while (next_use = queue.shift)
      data, enumerator = next_use
      date, amount = data
      yield date, amount
      enqueue[enumerator]
    end
  end

  def depletes_on(from_date = Date.today)
    validate!

    unless from_date.is_a?(Date)
      raise ArgumentError, 'from_date must be a date'
    end

    remaining_amount = amount
    each_use(from_date).each do |date, amount|
      remaining_amount -= amount
      break date - 1 if remaining_amount.negative?
    end
  end

  private

  def validate_amount
    add_error(:amount, 'must be an integer') unless amount.is_a?(Integer)
  end
end
