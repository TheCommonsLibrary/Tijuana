require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PetitionSignature do
  describe 'handling required custom fields' do
    def validated_petition_signature(attrs)
      ps = create(:petition_signature)
      ps.update_attributes attrs
      ps.valid?
      ps
    end

    context 'unique attribute' do
      context 'with string values' do
        before :each do
          custom_fields = [
              {type: 'select',
               name: 'item',
               unique: true,
               required: true,
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

          @page = create(:page_with_parent)
          @petition = create(:petition_module, custom_fields: {:form_fields => custom_fields})
        end

        it 'should validate custom field' do
          validated_petition_signature(:dynamic_attributes => {'item' => 'Option 1 Value'}, :content_module => @petition, page: @page).should be_valid
          validated_petition_signature(:content_module => @petition, page: @page).should_not be_valid
        end

        it 'should not validate if all options are selected' do
          create(:petition_signature, dynamic_attributes: {'item' => 'Option 1 Value'}, page: @page)
          create(:petition_signature, dynamic_attributes: {'item' => 'Option 2 Value'}, page: @page)

          validated_petition_signature(:content_module => @petition, :page => @page).should be_valid
        end

        context 'with prompt text' do
          it 'should not validate if all options are selected' do
            custom_fields = [
                {type: 'select',
                 name: 'item',
                 unique: true,
                 required: true,
                 label: 'Label Text',
                 options: [
                     {
                         text: '-- Select an option --',
                         value: ''
                     },
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

            page = create(:page_with_parent)
            petition = create(:petition_module, custom_fields: {:form_fields => custom_fields})

            create(:petition_signature, dynamic_attributes: {'item' => 'Option 1 Value'}, page: page)
            create(:petition_signature, dynamic_attributes: {'item' => 'Option 2 Value'}, page: page)

            validated_petition_signature(:content_module => petition, :page => page).should be_valid
          end
        end
      end
    end

    context 'with non-string values' do
      before :each do
        custom_fields = [
            {type: 'select',
             name: 'item',
             unique: true,
             required: true,
             label: 'Label Text',
             options: [
                 {
                     text: 'Option 1 Text',
                     value: 34567
                 },
                 {
                     text: 'Option 2 Text',
                     value: 34568
                 }
             ]
            }]

        @page = create(:page_with_parent)
        @petition = create(:petition_module, custom_fields: {:form_fields => custom_fields})
      end

      it 'should validate custom field' do
        validated_petition_signature(:dynamic_attributes => {'item' => '34567'}, :content_module => @petition, page: @page).should be_valid
      end
    end
  end
end