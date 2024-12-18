require_relative 'recurring_use'

inventory_item = InventoryItem.new(amount: 70)
inventory_item.recurring_uses << RecurringUse.new(
  amount: 7,
  start_date: Date.new(2025, 1, 1),
  end_date: Date.new(2025, 1, 3),
  period: :daily
)
inventory_item.recurring_uses << RecurringUse.new(
  amount: 2,
  start_date: Date.new(2025, 1, 3),
  period: :daily
)
inventory_item.recurring_uses << RecurringUse.new(
  amount: 3,
  start_date: Date.new(2025, 1, 2),
  end_date: Date.new(2025, 1, 15),
  period: :weekly,
  weekday: :wednesday
)
inventory_item.recurring_uses << RecurringUse.new(
  amount: 1,
  start_date: Date.new(2025, 1, 1),
  period: :weekly,
  weekday: :friday,
)

usage_dates = {}
left = inventory_item.amount
inventory_item.each_use(Date.new(2025, 1, 1)) do |date, used|
  left -= used

  if usage_dates[date]
    prev_left, prev_used = usage_dates[date]
    usage_dates[date] = [left, prev_used + used]
  else
    usage_dates[date] = [left, used]
  end

  break if left.negative?
end

puts "Depletes on #{inventory_item.depletes_on}"
usage_dates.each do |date, usage_data|
  left, used = usage_data
  print "#{date}: "
  print "\033[#{32}m#{'*' * [left, 0].max}\033[0m"
  print "\033[#{31}m#{'*' * used}\033[0m"
  print " (#{left} - #{used})"
  puts
end

