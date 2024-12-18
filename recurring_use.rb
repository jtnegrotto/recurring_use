require 'date'

module Model
  class ValidationError < StandardError
    attr_reader :model

    def initialize(model)
      super("Validation failed for #{model.class}")
      @model = model
    end
  end

  def included base
    base.extend ClassMethods
  end

  module ClassMethods
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

  def next_date(from_date = Date.today)
    validate!

    unless from_date && from_date.is_a?(Date)
      raise ArgumentError, 'from_date must be a date'
    end

    effective_start_date = [start_date, from_date].max

    next_use_date =
      if daily?
        effective_start_date
      elsif weekly?
        weekday_index = WEEKDAYS.index(weekday)
        weekday_offset = (weekday_index - effective_start_date.wday) % 7
        effective_start_date + weekday_offset
      else
        raise NotImplementedError, "period #{period} not implemented"
      end

    if end_date && end_date < next_use_date
      return nil
    end

    next_use_date
  end

  private

  def validate_amount
    unless amount.is_a?(Integer)
      errors[:amount] << 'must be an integer'
      return
    end

    if amount.negative?
      errors[:amount] << 'must not be negative'
    end
  end

  def validate_start_date
    unless start_date.is_a?(Date)
      errors[:start_date] << 'must be a date'
    end
  end

  def validate_end_date
    return if end_date.nil?

    unless end_date.is_a?(Date)
      errors[:end_date] << 'must be a date or nil'
      return
    end

    return unless start_date && start_date.is_a?(Date)
    unless end_date >= start_date
      errors[:end_date] << 'cannot be before start_date'
    end
  end

  def validate_period
    unless PERIODS.include?(period)
      errors[:period] << "must be one of #{PERIODS.map(&:inspect).join(', ')}"
    end
  end

  def validate_weekday
    if weekly? && weekday.nil?
      errors[:weekday] << 'must be present when period is weekly'
    end

    if weekday && !WEEKDAYS.include?(weekday)
      errors[:weekday] << "must be one of #{WEEKDAYS.map(&:inspect).join(', ')}"
    end
  end
end
