namespace :import do

  desc 'Import signatures from CSV file and adds them to petition module on supplied page. New users are NOT added as members. Usage: rake import:signatures[<PAGE_ID>,<SIGNATURE_FILE>]'
  task :signatures, [:page_id, :signature_file] => [:environment]  do |t, args|
    raise 'Usage: rake import:signatures[<PAGE_ID>,<SIGNATURE_FILE>]' if args[:page_id].blank? || args[:signature_file].blank?
    require_relative('signature_importer')
    page = Page.find(args[:page_id])
    petition_module = page.content_modules.where(type: 'PetitionModule').first
    raise 'Page with petition module required' if petition_module.nil?

    importer = SignatureImporter.new
    importer.import(args[:signature_file], page, petition_module)
  end
end
