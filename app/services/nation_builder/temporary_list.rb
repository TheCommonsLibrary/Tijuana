module NationBuilder
  class TemporaryList
    AUTHOR_ID = 1 # nationbuilder support; guaranteed to exist

    def self.create(tags)
      resp = NationBuilder::Api.call_api :lists, :create, list: list_params(tags)
      new(resp["list_resource"]["id"], tags)
    end

    def add_people(user_ids)
      nb_ids(user_ids).in_groups_of(100_000, false) { |ids| add_nb_people ids }
    end

    def apply_tags!
      NationBuilderSyncable.sync_tags(@tags).each { |tag| apply_tag(tag) }
    end

    def destroy!
      NationBuilder::Api.call_api :lists, :destroy, id: @nb_list_id
    end

    private

    def initialize(nb_list_id, tags)
      @nb_list_id = nb_list_id
      @tags = tags
    end

    def add_nb_people(nb_ids)
      NationBuilder::Api.call_api :lists, :add_people, list_id: @nb_list_id, people_ids: nb_ids
    end

    def nb_ids(user_ids)
      NationBuilderUser.where(user_id: user_ids).pluck(:nationbuilder_id)
    end

    def apply_tag(tag)
      NationBuilder::Api.call_api :lists, :add_tag, list_id: @nb_list_id, tag: URI.escape(tag)
    end

    def self.list_params(tags)
      {
        name: "Tijuana temporary list for '#{tags.join(",")}'",
        slug: "autotag_#{SecureRandom.hex(6)}", # max length in NB is 20
        author_id: AUTHOR_ID,
      }
    end
  end
end
