# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.paths << Rails.root.join("app", "assets", "fonts")

Rails.application.config.assets.precompile += [
    # needed for dashboard in dev for some reason?
    'webfonts/eef71022c96a9c1721e0c0623ec70f9d.css',

    'election_app.js',
    'public.js',
    'events.js',
    'dashboard.js',
    'facebook_share_module.js',
    'image_share_tool.js',
    'facebook_sign_petition.js',
    'testimonial_module.js',
    'recommendation_module.js',
    'common/lib/jquery.min.js',
    'common/lib/jquery.validate.js',
    'common/lib/jquery-ui.js',
    'common/lib/html5.js',
    'common/lib/tijuana.trackjs.js',
    'admin.js',
    'legacy/public.js',
    'public/lib/jquery.jcarousel.js', # pokies theme
    'public/lib/fontfaceonload.js',
    'themes/openletter/openletter.js',
    'themes/nbia/nbia.js',
    'themes/heroes/heroes_video_display.js',
    'themes/map/map.js',
    'external_site.js',
    'embed.js',
    'embedded.js',

    # Legacy css
    'common/legacy-screen.css',
    'common/legacy-reset.css',
    'common/ie-screen.css',
    'common/ie9-screen.css',
     # Top level css
    'dashboard.css',
    'admin.css',
    'public.css',
    'events.css',
    'election_app.css',
    'scorecard.css',
    'public/new_modal.css',
    'public/email_pledges.css',
    'public/recommendation_module.css',

     # Themes
    'themes/screen-communityrun.css',
    'themes/screen-happy.css',
    'themes/screen-pokies.css',
    'themes/screen-sad.css',
    'themes/screen-out-of-sight.css',
    'themes/screen-dtj.css',
    'themes/screen-nbia.css',
    'themes/screen-openletter.css',
    'themes/screen-heroes.css',
    'themes/screen-map.css',
    'themes/screen-daisy_chain.css',
    'themes/getup2018.css',

    'htv/screen.css',
    'htv/animate.css',
    'htv/tabbed.css',
]
