require 'spec_helper'

describe HomeController do
  before{ Rails.cache.clear }
  render_views
  let!(:homepage){ create(:homepage) }
  let!(:member_count_calculator){ create(:member_count_calculator) }

  context "with an active remarketing campaign" do
    let!(:remarketing_campaign){ create(:remarketing_campaign) }

    it 'should not show the remarketing content by default' do
      get :index
      expect(response.body).to_not include(remarketing_campaign.content)
    end

    context 'with a user with the user_id cookie set and a matching tag' do
      let!(:user) { create(:user) }
      before do
        cookies.signed['user_id'] = user.id.to_s
        user.tag_list = remarketing_campaign.tags
        user.save!
      end

      it 'should show the remarketing content' do
        get :index
        expect(response.body).to include(remarketing_campaign.content)
      end

      it 'should record an event' do
        get :index
        expect(EventTrackingLog.remarketing.where(context: remarketing_campaign.id)).to be_exist
      end

      context 'with multiple remarketing content available' do
        let!(:campaign_with_equal_high_priority){ create(:remarketing_campaign, content: '<b>display</b>', tags: remarketing_campaign.tags.first) }
        let!(:campaign_with_lower_priority){ create(:remarketing_campaign, content: '<b>do not show</b>', tags: remarketing_campaign.tags.first, priority: 10) }

        it 'should display the campaigns with the highest priority' do
          get :index
          expect(response.body).to include(remarketing_campaign.content)
          expect(response.body).to include(campaign_with_equal_high_priority.content)
          expect(response.body).to_not include(campaign_with_lower_priority.content)
        end
      end
    end
  end
end


describe PagesController do
  before{ Rails.cache.clear }
  render_views

  context 'with an active remarketing campaign' do
    let!(:remarketing_campaign){ create(:remarketing_campaign) }
    let!(:user){ create(:user) }
    let!(:page){ create(:page_with_parent, name: 'showcase') }

    it 'should not show the remarketing content by default' do
      get_page(page)
      expect(response.body).to_not include(remarketing_campaign.content)
    end

    context 'with a user with the user_id cookie set and a matching tag' do
      before do
        cookies.signed['user_id'] = user.id.to_s
        user.tag_list = remarketing_campaign.tags
        user.save!
      end

      it 'should show the remarketing content' do
        get_page(page)
        expect(response.body).to include(remarketing_campaign.content)
      end

      it 'should record an event' do
        get_page(page)
        expect(EventTrackingLog.remarketing.where(context: remarketing_campaign.id)).to be_exist
      end

      context 'on an ask page' do
        let!(:ask){ create(:donation_module) }
        let!(:link){ ContentModuleLink.create!(page: page, content_module: ask, layout_container: :sidebar) }

        it 'should not show the remarketing content' do
          get_page(page)
          expect(response.body).to_not include(remarketing_campaign.content)
        end

        context "with a page with enable-remarketing set as a tag" do
          before do
            page.tag_list = 'enable-remarketing'
            page.save!
          end

          it 'should show the remarketing content' do
            get_page(page)
            expect(response.body).to include(remarketing_campaign.content)
          end

          context "with tag disable-remarketing-campaign-:id set on a page" do
            let!(:disabled_campaign){ create(:remarketing_campaign, content: '<b>do not display</b>') }
            before do
              page.tag_list += ",disable-remarketing-#{disabled_campaign.id}"
              page.save!
            end

            it 'should not show the content' do
              get_page(page)
              expect(response.body).to include(remarketing_campaign.content)
              expect(response.body).to_not include(disabled_campaign.content)
            end
          end
        end

        context 'with an ask submitted that uses the secure cookie but does not pass validation' do
          let!(:post_triggering_failed_action){ {
              module_id: ask.id,
              use_cookie: 1,
              campaign_id: page.page_sequence.campaign.friendly_id,
              page_sequence_id:  page.page_sequence.friendly_id,
              donation: { payment_method: 'credit_card' },
              id: page.id,
              petition_signature: {}
            } }

          it 'should not show the remarketing content on the validation error page' do
            post :take_action, post_triggering_failed_action
            expect(response).to render_template('pages/show')
            expect(response.body).to_not include(remarketing_campaign.content)
          end
        end
      end

      context 'the user has seen the page already in the session' do
        it 'should not show the remarketing content' do
          get_page(page)
          expect(response.body).to include(remarketing_campaign.content)
          get_page(page)
          expect(response.body).to_not include(remarketing_campaign.content)
        end
      end
    end
  end
end
