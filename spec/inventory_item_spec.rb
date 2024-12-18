require 'spec_helper'

describe InventoryItem do
  subject(:inventory_item) do
    described_class.new(amount: 100)
  end

  describe 'validations' do
    describe 'amount' do
      it 'may be an integer' do
        is_expected.to allow_value(1).for(:amount)
      end

      it 'may not be nil' do
        is_expected.to_not allow_value(nil).for(:amount)
      end

      it 'may not be a non-integer' do
        is_expected.to_not allow_value(1.5).for(:amount)
      end
    end
  end

  describe '#each_use(from_date)' do
    let(:today) { Date.new(2025, 1, 1) }

    it 'returns a lazy enumerator' do
      expect(inventory_item.each_use).to be_a(Enumerator::Lazy)
    end

    context 'one daily recurring use' do
      before do
        inventory_item.recurring_uses = [
          RecurringUse.new(
            amount: 10, start_date: Date.new(2025, 1, 1), period: :daily
          )
        ]
      end

      it 'yields the date and amount of each use' do
        uses = inventory_item.each_use(today)
        expect(uses.take(3).to_a).to eq([
          [today, 10],
          [today + 1, 10],
          [today + 2, 10]
        ])
      end
    end

    context 'one weekly recurring use' do
      before do
        inventory_item.recurring_uses = [
          RecurringUse.new(
            amount: 10, start_date: Date.new(2025, 1, 1), period: :weekly,
            weekday: :monday
          )
        ]
      end

      it 'yields the date and amount of each use' do
        monday = today + 5 # 2025-01-06 is a Monday
        uses = inventory_item.each_use(today)
        expect(uses.take(3).to_a).to eq([
          [monday, 10],
          [monday + 7, 10],
          [monday + 14, 10]
        ])
      end
    end

    context 'multiple recurring uses' do
      before do
        inventory_item.recurring_uses = [
          RecurringUse.new(
            amount: 10, start_date: Date.new(2025, 1, 1), period: :daily
          ),
          RecurringUse.new(
            amount: 20, start_date: Date.new(2025, 1, 1), period: :weekly,
            weekday: :monday
          )
        ]
      end

      it 'yields the date and amount of each use' do
        sunday = today + 4 # 2025-01-06 is a Sunday
        uses = inventory_item.each_use(sunday)
        next_uses = uses.take(4).to_a

        # Daily use on Sunday
        expect(next_uses.first).to eq([sunday, 10])
        # Daily and weekly uses on Monday (any order)
        expect(next_uses.slice(1, 2)).to match_array([
          [sunday + 1, 10],
          [sunday + 1, 20]
        ])
        # Daily use on Tuesday
        expect(next_uses.last).to eq([sunday + 2, 10])
      end
    end
  end

  describe '#depletes_on(from_date)' do
    let(:today) { Date.new(2025, 1, 1) }

    context 'one daily recurring use' do
      before do
        inventory_item.recurring_uses = [
          RecurringUse.new(amount: 10, start_date: today, period: :daily)
        ]
      end

      it 'returns the date the item will be depleted' do
        expect(inventory_item.depletes_on).to eq(today + 9)
      end
    end

    context 'one weekly recurring use' do
      before do
        inventory_item.amount = 25
        inventory_item.recurring_uses = [
          RecurringUse.new(
            amount: 10, start_date: today, period: :weekly,
            weekday: :monday
          )
        ]
      end

      it 'returns the date the item will be depleted' do
        expect(inventory_item.depletes_on).to eq(
          Date.new(2025, 1, 19) # Next day is the third Monday
        )
      end
    end

    context 'multiple recurring uses' do
      before do
        inventory_item.amount = 55
        inventory_item.recurring_uses = [
          RecurringUse.new(amount: 10, start_date: today, period: :daily),
          RecurringUse.new(
            amount: 20, start_date: today, period: :weekly,
            weekday: :friday
          )
        ]
      end

      it 'returns the date the item will be depleted' do
        # w -10, t -10, f -30, s -10 (fail)
        expect(inventory_item.depletes_on).to eq(Date.new(2025, 1, 3))
      end
    end

    context 'there are no recurring uses' do
      it 'returns nil' do
        inventory_item.recurring_uses = []
        expect(inventory_item.depletes_on).to be_nil
      end
    end

    context 'the inventory item is invalid' do
      it 'raises a validation error' do
        inventory_item.amount = nil
        expect { inventory_item.depletes_on }.to raise_error(Model::ValidationError)
      end
    end

    context 'from_date is not a date' do
      it 'raises an argument error' do
        expect { inventory_item.depletes_on('today') }.to raise_error(ArgumentError)
      end
    end
  end
end
