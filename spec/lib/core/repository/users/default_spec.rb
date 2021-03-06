module Core
  RSpec.describe Repository::Users::Default do
    describe '#update_from_crm' do
      context 'when customer_id is blank' do
        it 'raises an exception' do
          expect { subject.update_from_crm(User.new) }.to raise_error(
            'customer_id is blank'
          )
        end
      end

      context 'when customer does not exist in CRM' do
        let(:user) { FactoryBot.create(:user) }
        subject { described_class.new }

        before :each do
          user
          Registry::Repository[:customer].clear
        end

        it 'raises an exception' do
          expect { subject.update_from_crm(user) }.to raise_error(
            'customer_id is blank'
          )
        end
      end

      context 'when customer exists in CRM' do
        let(:user) { FactoryBot.create(:user) }
        subject { described_class.new }

        before :each do
          Interactors::Customer::Creator.new(user).call
          customer = Registry::Repository[:customer].customers.first
          customer[:first_name] = 'Newfirstname'
          customer[:last_name] = 'Newlastname'
          customer[:email] = 'new@example.com'
          customer[:post_code] = 'NE1 6AA'
          customer[:gender] = 'female'
          customer[:age_range] = '0-15'
          customer[:date_of_birth] = '01/01/1988'
          customer[:newsletter_subscription] = 'false'
          customer[:active] = 'true'
          # topics to be implemented

          subject.update_from_crm(user)
          user.reload
        end

        it 'updates user with CRM data' do
          expect(user.first_name).to eql('Newfirstname')
          expect(user.last_name).to eql('Newlastname')
          expect(user.email).to_not eql('new@example.com') # does not update email
          expect(user.post_code).to eql('NE1 6AA')
          expect(user.gender).to eql('female')
          expect(user.age_range).to eql('0-15')
          expect(user.date_of_birth).to eql(Time.new(1988, 1, 1).utc.to_datetime)
          expect(user.newsletter_subscription).to eql(false)
          expect(user.active).to eql(true)
        end
      end
    end
  end
end
