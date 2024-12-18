require 'spec_helper'

describe RecurringUse do
  subject(:recurring_use) do
    described_class.new(amount: 100, start_date: Date.today, period: :daily)
  end

  describe 'validations' do
    describe 'amount' do
      it 'may be a positive integer' do
        is_expected.to allow_value(1).for(:amount)
      end

      it 'may be zero' do
        is_expected.to allow_value(0).for(:amount)
      end

      it 'may not be a negative integer' do
        is_expected.to_not allow_value(-1).for(:amount)
      end

      it 'may not be nil' do
        is_expected.to_not allow_value(nil).for(:amount)
      end

      it 'may not be a non-integer' do
        is_expected.to_not allow_value(1.5).for(:amount)
      end
    end

    describe 'start_date' do
      it 'may be a date' do
        is_expected.to allow_value(Date.today).for(:start_date)
      end

      it 'may not be nil' do
        is_expected.to_not allow_value(nil).for(:start_date)
      end

      it 'may not be a non-date' do
        is_expected.to_not allow_value('today').for(:start_date)
      end
    end

    describe 'end_date' do
      let(:start_date) { Date.today }
      before { recurring_use.start_date = start_date }

      it 'may be a date' do
        is_expected.to allow_value(Date.today).for(:end_date)
      end

      it 'may not be before start_date' do
        is_expected.to_not allow_value(start_date - 1).for(:end_date)
      end

      it 'may be nil' do
        is_expected.to allow_value(nil).for(:end_date)
      end

      it 'may not be a non-date' do
        is_expected.to_not allow_value('today').for(:end_date)
      end
    end

    describe 'period' do
      let(:weekday) { :sunday }
      before { recurring_use.weekday = weekday }

      it 'may be :daily' do
        is_expected.to allow_value(:daily).for(:period)
      end

      it 'may be :weekly' do
        is_expected.to allow_value(:weekly).for(:period)
      end

      it 'may not be nil' do
        is_expected.to_not allow_value(nil).for(:period)
      end

      it 'may not be some other symbol' do
        is_expected.to_not allow_value(:yesterday).for(:period)
      end

      it 'may not be some other value' do
        is_expected.to_not allow_value('daily').for(:period)
      end
    end

    describe 'weekday' do
      let(:period) { :daily }
      before { recurring_use.period = period }

      it 'may be a valid weekday' do
        is_expected.to allow_value(:sunday).for(:weekday)
      end

      context 'when period is :daily' do
        it 'may be nil' do
          is_expected.to allow_value(nil).for(:weekday)
        end
      end

      context 'when period is :weekly' do
        let(:period) { :weekly }

        it 'may not be nil' do
          is_expected.to_not allow_value(nil).for(:weekday)
        end
      end
    end
  end

  describe '#next_date(from_date)' do
    # Wednesday, January 1, 2025
    let(:today) { Date.new(2025, 1, 1) }

    it 'returns the next date starting on from_date' do
      expect(recurring_use.next_date(today)).to eq(today)
    end

    it 'handles weekly recurring uses' do
      recurring_use.period = :weekly
      recurring_use.weekday = :sunday
      expect(recurring_use.next_date(today)).to eq(Date.new(2025, 1, 5))
    end

    context 'start_date is before from_date' do
      before { recurring_use.start_date = today - 1 }

      it 'starts from from_date' do
        expect(recurring_use.next_date(today)).to eq(today)
      end
    end

    context 'start_date is after from_date' do
      before { recurring_use.start_date = today + 1 }

      it 'starts from start_date' do
        expect(recurring_use.next_date(today)).to eq(today + 1)
      end
    end

    context 'end_date is before next date' do
      context 'daily' do
        before do
          recurring_use.start_date = today - 1
          recurring_use.end_date = today - 1
        end

        it 'returns nil' do
          expect(recurring_use.next_date(today)).to be_nil
        end
      end

      context 'weekly' do
        before do
          recurring_use.period = :weekly
          recurring_use.weekday = :monday
          recurring_use.end_date = Date.new(2025, 1, 5)
        end

        it 'returns nil' do
          expect(recurring_use.next_date(today)).to be_nil
        end
      end
    end

    context 'record is invalid' do
      it 'raises a validation error' do
        recurring_use.end_date = 'today'
        expect { recurring_use.next_date(today) }.to raise_error(Model::ValidationError)
      end
    end

    context 'from_date is not a date' do
      it 'raises an argument error' do
        expect { recurring_use.next_date('today') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#uses(from_date)' do
    it 'returns a lazy enumerator' do
      uses = recurring_use.uses
      expect(uses).to be_a(Enumerator::Lazy)
    end

    it 'yields each use starting from from_date' do
      uses = recurring_use.uses(Date.new(2025, 1, 1))
      expect(uses.take(3).to_a).to eq([
        Date.new(2025, 1, 1),
        Date.new(2025, 1, 2),
        Date.new(2025, 1, 3),
      ])
    end

    it 'handles weekly recurring uses' do
      recurring_use.period = :weekly
      recurring_use.weekday = :sunday
      uses = recurring_use.uses(Date.new(2025, 1, 1))
      expect(uses.take(3).to_a).to eq([
        Date.new(2025, 1, 5),
        Date.new(2025, 1, 12),
        Date.new(2025, 1, 19),
      ])
    end
  end
end
