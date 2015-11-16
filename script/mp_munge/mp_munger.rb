require 'rubygems'
require 'pry'
require 'CSV'

#USAGE: $ ruby mp_munger.rb <OUTPUT_FILE> <PARTIES> <ELECTORATES>
DEFAULT_PARTIES_CSV = 'parties.csv'
DEFAULT_ELECTORATES_CSV = 'electorates.csv'
DEFAULT_OUTPUT_CSV = 'mp_data.csv'

def blank?(str)
  str == nil || str.strip.length == 0
end

def read_input_csv(file)
  csv_rows = []
  input = file
  CSV.foreach(input) do |row|
    csv_rows << row
  end
  csv_rows
end

def write_csv(rows)
  output = ARGV[0] || DEFAULT_OUTPUT_CSV
  CSV.open(output, 'wb') do |csv|
    rows.each do |row|
      csv << row
    end
  end
end

def has_email_entry?(row)
  row[1] =~ /^E-mail:/
end

def record_electorate_contacts(mp, electorate_office)
  tel, fax = electorate_office.split(', Fax : ')
  mp['electorate-tel'] = tel.sub('Tel : ', '')
  mp['electorate-fax'] = fax
  mp['electorate-tel'].strip if mp['electorate-tel']
  mp['electorate-fax'].strip if mp['electorate-fax']
end

def record_contact_details(row, mp)
  mp['electorate'] = row[0].sub(',','') if !blank?(row[0]) && blank?(mp['electorate'])
  mp['email'] = row[1].split('E-mail:')[1].strip if has_email_entry?(row)
  mp['tel'] = row[2].split('Tel:')[1].strip if row[2] =~ /^Tel:/
  mp['fax'] = row[2].split('Fax:')[1].strip if row[2] =~ /^Fax:/
  record_electorate_contacts(mp, row[1]) if row[1] =~ /Tel : /
end

def extract_contact_details(rows)
  mps = {}
  mp = Hash.new
  rows.each do |row|
    record_contact_details(row, mp)
    if has_email_entry?(row)
      mps[mp['electorate']] = mp
      mp = Hash.new
    end
  end
  mps
end

def merge_details(mps, contact_details)
  mps.each_with_index do |mp_row, index|
    mp_details = contact_details[mp_row[13]]
    if mp_details
      mp_row << mp_details['email'].downcase
      #puts "Overwriting TEL for #{mp_row[13]} with: #{mp_details['tel']}" if mp_row[9] != mp_details['tel']
      #puts "Overwriting FAX for #{mp_row[13]} with: #{mp_details['fax']}" if mp_row[10] != mp_details['fax']

      mp_row[9] = mp_details['tel'] unless blank?(mp_details['tel'])
      mp_row[10] = mp_details['fax'] unless blank?(mp_details['fax'])
      mp_row[19] = mp_details['electorate-tel'] unless blank?(mp_details['electorate-tel'])
      mp_row[18] = mp_details['electorate-fax'] unless blank?(mp_details['electorate-fax'])
    else
      puts "!Could not find contact details for: #{mp_row[13]}"
    end
  end
end

FEDERAL_JURISDICTION = '9'

def convert_parties(mps)
  parties_rows = read_input_csv(ARGV[1] || DEFAULT_PARTIES_CSV)
  parties = {} # map abbreviation to ID
  parties_rows.each do |row|
    parties[row[2]] = row[0] if row[3] == FEDERAL_JURISDICTION
  end

  mps.each do |mp|
    if parties[mp[11]]
      mp << parties[mp[11]]
    else
      puts "@@@ Could not find matching party for #{mp[11]}"
    end
  end
end

def convert_electorates(mps)
  electorate_rows = read_input_csv(ARGV[2] || DEFAULT_ELECTORATES_CSV)
  electorates = {} # map electorate name to ID
  electorate_rows.each do |row|
    electorates[row[1]] = row[0] if row[2] == FEDERAL_JURISDICTION
  end

  mps.each do |mp|
    if electorates[mp[13]]
      mp << electorates[mp[13]]
    else
      puts "@@ Unable to find electorate to match #{mp[13]}"
    end
  end
end


mp_details = read_input_csv('SurnameRepsCSV.csv')
mp_contact_details = read_input_csv('mp_from_pdf.csv')

contact_details = extract_contact_details(mp_contact_details)
merge_details(mp_details, contact_details)
convert_parties(mp_details)
convert_electorates(mp_details)

write_csv(mp_details)
