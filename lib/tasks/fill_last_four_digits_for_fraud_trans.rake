desc "fill card last 4 digits in fraudulent"
task :fill_fraudulent_card_info => :environment do
   CSV.open('doc/fraudulent_transactions.csv').each_with_index do |line, index|
    unless index == 0
      donation_id = Transaction.find(line[0]).donation_id
      card_last_four_digits = Donation.find(donation_id).card_last_four_digits
      line += [card_last_four_digits]
      puts line.to_csv
    end
 end
end
#cat input.csv | heroku run rake add_digits > output.csv

