require 'spec_helper'

describe Admin::AcquisitionSourcesHelper do

  describe "#redirects_for_share_link" do
    context "with multiple pages with the same name" do
      let!(:page){ create(:page_with_parent, name: 'test') }
      let!(:source){ create(:acquisition_source, page: page) }
      let!(:redirect){ create(:redirect_path, alias_path: 'test-redirect-1', target: helper.friendly_path_from_acq_source(source)) }
      let!(:page_duplicate){ create(:page_with_parent, name: 'test', page_sequence: page.page_sequence) }
      let!(:source_duplicate){ create(:acquisition_source, page: page_duplicate, content: 'v2') }
      let!(:page_duplicate_redirect){ create(:redirect_path, alias_path: 'test-redirect-2', target: helper.friendly_path_from_acq_source(source_duplicate)) }

      it "should a single redirect for the correct page" do
        expect(helper.redirects_for_share_link(source)).to eq([redirect]) 
      end

      context "with extra parameters on the redirect" do
        let!(:redirect_with_params){ create(:redirect_path, alias_path: 'test-redirect-3', target: helper.friendly_path_from_acq_source(source, some: 'param')) }

        it "should handle both redirects" do
          expect(helper.redirects_for_share_link(source)).to eq([redirect, redirect_with_params])
        end
      end
    end
  end
end
