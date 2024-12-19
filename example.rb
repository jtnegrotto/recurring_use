require_relative 'recurring_use'

inventory_item = InventoryItem.new(amount: 60)
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
    break if remaining < -10
  end

# Print the results

def ansi(string, color: nil, bold: false)
  color_code = case color
               when :red then 31
               when :green then 32
               when :yellow then 33
               else nil
               end
  bold_code = bold ? 1 : nil
  code_sequence = [color_code, bold_code].compact.join(";")
  ansi_code = ["\33[", code_sequence, "m"].join
  reset_code = "\33[0m"
  "#{ansi_code}#{string}#{reset_code}"
end

bar = "\u2588"
max = usages.first.last[:initial]
usages.each do |date, data|
  initial, remaining = data.values_at(:initial, :remaining)
  usage = initial - remaining
  available = [remaining, 0].max
  deficit = [-remaining, 0].max
  acceptable_usage = [initial, 0].max - available
  space = max - available - acceptable_usage - deficit

  status_color =
    if remaining > max / 3
      :green
    elsif remaining > 0
      :yellow
    else
      :red
    end

  line = []
  line << ansi("#{date}", bold: true)
  line << ": "
  line << ansi(bar * available, color: :green)
  line << ansi(bar * acceptable_usage, color: :yellow)
  line << ansi(bar * deficit, color: :red)
  line << " " * space
  line << ansi(sprintf("%3d", initial), bold: true)
  line << " -> "
  line << ansi(sprintf("%3d", remaining), color: status_color, bold: true)
  line << " ("
  line << ansi(sprintf("%3d", -usage), color: :red, bold: true)
  line << ")\n"
  puts line.join
end

puts ansi("Depletes on #{inventory_item.depletes_on}", bold: true, color: :red)

