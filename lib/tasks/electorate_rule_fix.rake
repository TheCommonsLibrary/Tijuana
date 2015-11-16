desc "Fix electorate rules"
task :electorate_rules_fix => :environment do
  to_update = ENV['UPDATE'] == 'true'
  list_ids =  [11,14,16,18,26,32,35,52,82,88,98,100,117,118,119,120,127,128,163,164,168,170,182,192,196,237,353,374,379,401,402,409,523,524,525,526,530,531,532,533,534,538,539,540,545,567,568,578,584,626,627,628,629,630,631,632,633,634,635,636,637,638,657,805,806,807,904,953,955,981,983,1187,1189,1191,1193,1195,1197,1199,1201,1203,1205,1207,1209,1211,1213,1215,1217,1219,1221,1223,1225,1227,1229,1231,1233,1235,1237,1239,1241,1243,1245,1247,1249,1251,1253,1255,1257,1259,1261,1263,1265,1267,1269,1271,1273,1275,1299]
  updated_ids = []
  
  list_ids.each do |id|
    puts "Trying to serialise #{id}"
    list = List.find(id)
    list.rules.each do |rule|
      if rule.instance_of? ListCutter::ElectorateRule
        if rule.electorate_ids.instance_of? String
          puts "Before #{id} = #{rule.electorate_ids}"
          ids_list = rule.electorate_ids.chomp(",").reverse.chomp(",").reverse.split(",").map(&:strip)
          rule.instance_variable_set(:@params, :electorate_ids => ids_list)
          puts "After #{id} = #{rule.electorate_ids}"
          list.save if to_update
          updated_ids << id
        end
      end
    end
  end
  puts "#{list_ids.count - updated_ids.count} have not been updated."
  puts (list_ids - updated_ids).inspect
end
