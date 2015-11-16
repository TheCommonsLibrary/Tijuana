# Tijuana - campaigning platform

## Setup

### Requirements for local dev / tests

- Xcode
- [Homebrew](https://brew.sh/)
- MySQL
- ImageMagick
- PhantomJS
- QT
- Firefox (optional; Selenium testing)

### External Dependencies

`xcode-select --install`
`brew install mysql@5.6 qt@5.5 imagemagick@6 phantomjs`
`brew install geckodriver` (optional; Selenium)

### Environment

`brew link --force imagemagick@6` so the rmagick gem will install
`echo 'export PATH="/usr/local/opt/qt@5.5/bin:$PATH"' >> ~/.zshrc` or add it your non-Zsh path your way

### Application Dependencies

`bundle install`

NB. if capybara-webkit complains, you may need to reset your xcode build path:
`sudo xcode-select --reset`

### Database

`brew services start mysql@5.6`
`rake db:create && rake db:schema:load && rake db:seed`


## Tests

Run `rake` for specs & scenarios, `rake cucumber` for legacy features, or `rspec` directly for individual files


## Running locally

- Setup your local env: `cp .env.sample .env` & add your own config details
- You may need to fill in some blanks in `./config/constants.yml`
- `foreman start`


## Cron

Cron handles the following things; if you don't use them, you can leave it off:

- Recurring donations
- Credit card expiring (dunning) emails
- Auto-tagging of large-ish donors
- Assigning daily random values to users for deterministic listcut splitting within any given day (for subject line tests)
- Updating the member count
- Updating the transparency stats (publicly visible donation aggregates)


## Deploying to Heroku

You'll need a MySQL database: for smaller setups [ClearDB](https://devcenter.heroku.com/articles/cleardb) is probably the way to go; larger setups should consider AWS RDS, especially [MySQL-Compatible Aurora](https://aws.amazon.com/rds/aurora/).

The only other addons needed to get going are [MemCachier](https://elements.heroku.com/addons/memcachier) and the [Scheduler](https://elements.heroku.com/addons/scheduler) for Cron.  You can probably add the [Sendgrid addon](https://elements.heroku.com/addons/sendgrid) but we configure it manually.
