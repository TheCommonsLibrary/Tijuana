require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ContentModuleHelper do
  describe 'render_custom_form_fields' do
    context "for select, without errors" do
      it "renders label and select" do
        custom_fields = [
            {type: 'select',
             name: 'FieldName',
             label: 'Label Text',
             options: [
                 {
                     text: 'Option 1 Text',
                     value: 'Option 1 Value'
                 },
                 {
                     text: 'Option 2 Text',
                     value: 'Option 2 Value'
                 }
             ]
            }]
        form = double("Form")
        form_object = double("Form Object", errors: {FieldName: []})
        form.should_receive(:object).and_return(form_object)
        form.should_receive(:label).with(:FieldName, 'Label Text').and_return "<label>Some Label</label>"
        form.should_receive(:select).with(:FieldName, [['Option 1 Text', 'Option 1 Value'], ['Option 2 Text', 'Option 2 Value']]).and_return("<select>Some Select</select>")
        helper.render_custom_form_fields(form, custom_fields, nil).should == "<label>Some Label</label><select>Some Select</select>"
      end
    end

    context "for select, with errors" do
      it "renders label select and error div" do
        custom_fields = [
            {type: 'select',
             name: 'FieldName',
             label: 'Label Text',
             options: [
                 {
                     text: 'Option 1 Text',
                     value: 'Option 1 Value'
                 },
                 {
                     text: 'Option 2 Text',
                     value: 'Option 2 Value'
                 }
             ]
            }]
        form = double("Form")
        form_object = double("Form Object", errors: {FieldName: ['MY ERROR']})
        form.should_receive(:object).and_return(form_object)
        form.should_receive(:label).with(:FieldName, 'Label Text').and_return "<label>Some Label</label>"
        form.should_receive(:select).with(:FieldName, [['Option 1 Text', 'Option 1 Value'], ['Option 2 Text', 'Option 2 Value']]).and_return("<select>Some Select</select>")
        helper.render_custom_form_fields(form, custom_fields, nil).should == "<label>Some Label</label><select>Some Select</select><div class='alert-block alert-error'>\nFieldname MY ERROR\n<\/div>\n"
      end
    end

    context 'for select, with unique' do
      let!(:page) { create(:page_with_parent) }
      let!(:content_module) { create(:petition_module) }
      let!(:petition_signature1) { create(:petition_signature, page_id: page.id, dynamic_attributes: {'FieldName' => '2'}) }
      let!(:petition_signature2) { create(:petition_signature, page_id: page.id, dynamic_attributes: {'FieldName' => '4'}) }

      before do
        @page = page
        @custom_fields = [
            {type: 'select',
             name: 'FieldName',
             unique: true,
             label: 'Label Text',
             options: [
                 {
                     text: 'Option 1 Text',
                     value: 'Option 1 Value'
                 },
                 {
                     text: 'Option 2 Text',
                     value: 2
                 },
                 {
                     text: 'Option 3 Text',
                     value: 'Option 3 Value'
                 },
                 {
                     text: 'Option 4 Text',
                     value: 4
                 }
             ]
            }]
      end

      it 'renders label and select with options that have not been chosen' do
        form = double('Form')
        form_object = double('Form Object', errors: {FieldName: []})
        form.should_receive(:object).and_return(form_object)

        form.should_receive(:label).with(:FieldName, 'Label Text').and_return '<label>Some Label</label>'
        form.should_receive(:select).with(:FieldName, [['Option 1 Text', 'Option 1 Value'], ['Option 3 Text', 'Option 3 Value']]).and_return '<select>Some Select</select>'
        helper.render_custom_form_fields(form, @custom_fields, content_module).should == '<label>Some Label</label><select>Some Select</select>'
      end

      context 'when all options have been chosen' do
        let!(:petition_signature3) { create(:petition_signature, page_id: page.id, dynamic_attributes: {'FieldName' => 'Option 1 Value'}) }
        let!(:petition_signature4) { create(:petition_signature, page_id: page.id, dynamic_attributes: {'FieldName' => 'Option 3 Value'}) }

        it 'does not render label and select' do
          form = double('Form')
          form_object = double('Form Object', errors: {FieldName: []})
          form.should_receive(:object).and_return(form_object)
          helper.render_custom_form_fields(form, @custom_fields, content_module).should == "<div class='clearfix'></div><div class='empty-field-text'></div>"
        end

        it 'renders a message in place of missing label and select' do
          @custom_fields[0][:no_options_text] = 'No Available Options'
          form = double('Form')
          form_object = double('Form Object', errors: {FieldName: []})
          form.should_receive(:object).and_return(form_object)
          helper.render_custom_form_fields(form, @custom_fields, content_module).should include 'No Available Options'
        end
      end
    end
  end
end
