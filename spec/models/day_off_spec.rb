require 'rails_helper'

RSpec.describe DayOff, type: :model do

  it "validacion basica" do
    expect(FactoryGirl.build(:global_day_off)).to be_valid
    expect(FactoryGirl.build(:branch_office_day_off)).to be_valid
    expect(FactoryGirl.build(:executive_day_off)).to be_valid
  end

  it "permite buscar por sucursal/ejecutivo, o global" do

    executive1 = FactoryGirl.create(:executive)
    executive2 = FactoryGirl.create(:executive)

    FactoryGirl.create(:global_day_off)
    FactoryGirl.create(:global_day_off)
    FactoryGirl.create(:global_day_off)
    FactoryGirl.create(:branch_office_day_off)
    FactoryGirl.create(:executive_day_off, :executive => executive1)
    FactoryGirl.create(:executive_day_off, :executive => executive1)
    FactoryGirl.create(:executive_day_off, :executive => executive2)

    expect(GlobalDayOff.count).to eq 3
    expect(BranchOfficeDayOff.count).to eq 1
    expect(ExecutiveDayOff.count).to eq 3
    expect(ExecutiveDayOff.where(:executive => executive1).count).to eq 2
    expect(ExecutiveDayOff.where(:executive => executive2).count).to eq 1

  end



end