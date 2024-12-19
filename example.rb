require_relative 'recurring_use'

inventory_item = InventoryItem.new(amount: 70)
# -7 from Jan 1, 2, 3
inventory_item.recurring_uses << RecurringUse.new(
  amount: 7,
  start_date: Date.new(2025, 1, 1),
  end_date: Date.new(2025, 1, 3),
  period: :daily
)
# -2 from Jan 3, 4, 5, ...
inventory_item.recurring_uses << RecurringUse.new(
  amount: 2,
  start_date: Date.new(2025, 1, 3),
  period: :daily
)
# -3 on Jan 8 & 15
inventory_item.recurring_uses << RecurringUse.new(
  amount: 3,
  start_date: Date.new(2025, 1, 2),
  end_date: Date.new(2025, 1, 15),
  period: :weekly,
  weekday: :wednesday
)
# -1 on Jan 3, 10, 17, 24, 31, ...
inventory_item.recurring_uses << RecurringUse.new(
  amount: 1,
  start_date: Date.new(2025, 1, 1),
  period: :weekly,
  weekday: :friday,
)

# Get the change in inventory until depletion
usages = {}
remaining = inventory_item.amount
inventory_item
  .each_use(Date.new(2025, 1, 1)) do |date, usage|
    initial = remaining
    remaining -= usage
    if usages[date]
      usages[date][:remaining] = remaining
    else
      usages[date] = { initial: initial, remaining: remaining }
    end
    break if remaining.negative?
  end

# Print the results
bar = "\u2588"
usages.each do |date, data|
  initial, remaining = data.values_at(:initial, :remaining)
  usage = initial - remaining
  available = [remaining, 0].max
  deficit = [-remaining, 0].max
  acceptable_usage = [initial, 0].max - available

  print "#{date}: "
  print "\33[32m#{bar * (available)}\33[0m"
  print "\33[33m#{bar * (acceptable_usage)}\33[0m"
  print "\33[31m#{bar * (deficit)}\33[0m"
  print " #{initial} -> #{remaining}"
  puts
end
puts "Depletes on #{inventory_item.depletes_on}"
