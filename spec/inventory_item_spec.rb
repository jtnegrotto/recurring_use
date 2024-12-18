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

  describe '#depletes_on(from_date)' do
    let(:today) { Date.new(2025, 1, 1) }

    context 'one daily recurring use' do
      it 'returns the date the item will be depleted' do
        inventory_item.recurring_uses = [
          RecurringUse.new(amount: 10, start_date: today, period: :daily)
        ]

        expect(inventory_item.depletes_on).to eq(today + 9)
      end
    end

    pending 'one weekly recurring use'

    pending 'multiple recurring uses'

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
