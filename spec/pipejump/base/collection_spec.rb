require 'spec_helper'

describe Pipejump::Collection do

  before do
    @session = PipejumpSpec.session
  end
  
  it ".all should return cached collections" do
    @session.contacts.size.should_not == 0
    @session.contacts.first.object_id.should == @session.contacts.first.object_id
  end
  
  it ".create should outdate cached collection" do 
    old_object_id = @session.contacts.first.object_id 
    @session.contacts.create(:name => 'Foo', :is_organisation => false)
    @session.contacts.first.object_id.should_not == old_object_id
  end
  
  it ".reload should work" do
    @session.contacts.size.should_not == 0
    old_object_id = @session.contacts.first.object_id     
    collection = @session.contacts.reload
    @session.contacts.first.object_id.should_not == old_object_id
    collection.class.should == Array
  end
  
end