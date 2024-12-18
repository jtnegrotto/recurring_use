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
end
