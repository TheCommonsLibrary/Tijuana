namespace :data do
  desc "output a list of friendly_id urls to 'tmp/paths.txt'"
  task :dump_friendly_id_urls => :environment do
    static_paths = ActiveRecord::Base.connection.execute("""
      SELECT REPLACE(CONCAT(
        '/', ps_slug.name, '--', ps_slug.sequence,
        '/', p_slug.name, '--', p_slug.sequence
      ),'--1', '') AS url

      FROM pages p
        JOIN slugs p_slug ON p.id = p_slug.sluggable_id AND p_slug.sluggable_type = 'Page'
      JOIN page_sequences ps ON p.page_sequence_id = ps.id
        JOIN slugs ps_slug ON ps.id = ps_slug.sluggable_id AND ps_slug.sluggable_type = 'PageSequence'

      WHERE p.deleted_at IS NULL AND ps.deleted_at IS NULL AND ps.campaign_id IS NULL
    """).each.flatten

    page_paths = ActiveRecord::Base.connection.execute("""
      SELECT REPLACE(CONCAT(
        '/campaigns/', c_slug.name, '--', c_slug.sequence,
        '/', ps_slug.name, '--', ps_slug.sequence,
        '/', p_slug.name, '--', p_slug.sequence
      ),'--1', '') AS url

      FROM pages p
        JOIN slugs p_slug ON p.id = p_slug.sluggable_id AND p_slug.sluggable_type = 'Page'
      JOIN page_sequences ps ON p.page_sequence_id = ps.id
        JOIN slugs ps_slug ON ps.id = ps_slug.sluggable_id AND ps_slug.sluggable_type = 'PageSequence'
      JOIN campaigns c ON ps.campaign_id = c.id
        JOIN slugs c_slug ON c.id = c_slug.sluggable_id AND c_slug.sluggable_type = 'Campaign'

      WHERE p.deleted_at IS NULL AND ps.deleted_at IS NULL AND c.deleted_at IS NULL
    """).each.flatten

    page_sequence_paths = ActiveRecord::Base.connection.execute("""
      SELECT REPLACE(concat(
        '/campaigns/', c_slug.name, '--', c_slug.sequence,
        '/', ps_slug.name, '--', ps_slug.sequence
      ),'--1', '') AS url

      FROM page_sequences ps
        JOIN slugs ps_slug ON ps.id = ps_slug.sluggable_id AND ps_slug.sluggable_type = 'PageSequence'
      JOIN campaigns c ON ps.campaign_id = c.id
        JOIN slugs c_slug ON c.id = c_slug.sluggable_id AND c_slug.sluggable_type = 'Campaign'

      WHERE ps.deleted_at IS NULL AND c.deleted_at IS NULL
    """).each.flatten

    admin_campaign_paths = ActiveRecord::Base.connection.execute("""
      SELECT REPLACE(concat('/admin/campaigns/', c_slug.name, '--', c_slug.sequence),'--1', '') AS url

      FROM campaigns c
        JOIN slugs c_slug ON c.id = c_slug.sluggable_id AND c_slug.sluggable_type = 'Campaign'

      WHERE c.deleted_at IS NULL
    """).each.flatten

    get_together_paths = ActiveRecord::Base.connection.execute("""
      SELECT REPLACE(CONCAT('/get_togethers/', `name`, '--', sequence),'--1', '') AS url
      FROM slugs
      WHERE sluggable_type = 'GetTogether'
    """).each.flatten

    event_paths = ActiveRecord::Base.connection.execute("""
      SELECT REPLACE(CONCAT('/events/', `name`, '--', sequence),'--1', '') AS url
      FROM slugs
      WHERE sluggable_type = 'Event'
    """).each.flatten

    File.open("#{Rails.root}/tmp/paths.txt", "w") do |file|
      local_variables.grep(/_paths$/).each do |paths|
        file.write eval(paths.to_s).join("\n")
      end
      file.write "\n"
    end

  end
end
