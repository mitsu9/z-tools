require "csv"
require "json"
require "net/http"

require "dotenv"

def fetch_views(subdomain, mail, access_token, page = 1)
  puts "fetch_views with page = #{page}"

  results = []
  url = "https://#{subdomain}.zendesk.com/api/v2/views.json?page=#{page}"
  uri = URI url
  req = Net::HTTP::Get.new "#{uri.path}?#{uri.query}"
  req.basic_auth "#{mail}/token", access_token
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request req }
  res_json = JSON.parse(response.body)
  results += res_json['views']
  if res_json['next_page']
    results += fetch_views(subdomain, mail, access_token, page + 1)
  end
  results
end

def fetch_groups_hash(subdomain, mail, access_token)
  puts "fetch groups"

  url = "https://#{subdomain}.zendesk.com/api/v2/groups.json"
  uri = URI url
  req = Net::HTTP::Get.new "#{uri.path}?#{uri.query}"
  req.basic_auth "#{mail}/token", access_token
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request req }
  res_json = JSON.parse(response.body)
  res_json["groups"].each_with_object({}) do |group, hash|
    id = group["id"]
    hash[id] = group["name"]
  end
end

def output_to_tsv(views, groups_hash, output_file)
  CSV.open(output_file,'w', :col_sep => "\t") do |f|
    f << ["id", "ビュー名", "グループ名"]
    views.each do |view|
      group = view['restriction'].nil? ? "全て" : groups_hash[view['restriction']['id']]
      arr = []
      arr << view['id']
      arr << view['title']
      arr << group
      f << arr
    end
  end
end

#### main ####
# アクティブで個人ビューを除いたビューをファイルに書き出す
Dotenv.load

subdomain    = ENV["ZENDESK_SUBDOMAIN"]
mail         = ENV["ZENDESK_MAIL_ADDRESS"]
access_token = ENV["ZENDESK_ACCESS_TOKEN"]

views = fetch_views(subdomain, mail, access_token)
groups_hash = fetch_groups_hash(subdomain, mail, access_token)

active_views, not_active_views = views.partition { |view| view['active'] == TRUE }
shared_views, personal_views = active_views.partition { |view| view['restriction'].nil? || view['restriction']['type'] == "Group" }

puts shared_views.count

output_to_tsv(shared_views, groups_hash, "active_views.tsv")
