require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe EmailTrackingFieldHelper do
  it "escapes t value" do
    helper.stub(:params).and_return({:t =>"<script>alert('pwn3d');</script>"})
    helper.email_tracking_field.should == 
      "<input type=\"hidden\" name=\"t\" value=\"&lt;script&gt;alert(&#39;pwn3d&#39;);&lt;/script&gt;\" />"
  end

  it "should read params and output hidden tag for tracking" do
    helper.stub(:params).and_return({:t =>"z"})
    helper.email_tracking_field.should == "<input type=\"hidden\" name=\"t\" value=\"z\" />"
  end

  it "should return an empty string if there is no t param" do
    helper.stub(:params).and_return({:not_t => "N/A" })
    helper.email_tracking_field.should be_nil
  end

end
