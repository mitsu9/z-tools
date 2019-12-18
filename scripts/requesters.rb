require 'csv'
require 'date'
require 'json'

require "dotenv"

require './lib/client.rb'

def fetch_requester(subdomain, mail, access_token, requester_id)
  url = "https://#{subdomain}.zendesk.com/api/v2/users/#{requester_id}.json"
  uri = URI url
  req = Net::HTTP::Get.new "#{uri.path}?#{uri.query}"
  req.basic_auth "#{mail}/token", access_token
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request req }
  json = JSON.parse(response.body)
  json['user']
end

def fetch_tickets_by_requester(subdomain, mail, access_token, requester_mail)
  query = "type:ticket requester:#{requester_mail}"
  encoded_query = URI.encode_www_form(query: query)
  url = "https://#{subdomain}.zendesk.com/api/v2/search.json?#{encoded_query}"
  uri = URI url
  req = Net::HTTP::Get.new "#{uri.path}?#{uri.query}"
  req.basic_auth "#{mail}/token", access_token
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request req }
  JSON.parse(response.body)
end

def create_requesters_hash(subdomain, mail, access_token, tickets)
  # requester_id -> requester_info のhashを作る
  requesters_hash = tickets.group_by { |t| t['requester_id'] }.each_with_object({}) { |(k, v), hash| hash[k] = { count: v.size } }

  # requesterの情報を取得
  idx = 0
  total_idx = requesters_hash.keys.count
  puts "fetch_requesters. count: #{total_idx}"
  requesters_hash.each_with_object({}) do |(requester_id, hash), result|
    requester = fetch_requester(subdomain, mail, access_token, requester_id)
    json = fetch_tickets_by_requester(subdomain, mail, access_token, requester['email'])
    result[requester_id] = hash.merge({ email: requester['email'], total_count: json['count'], role: requester['role'] })
    idx += 1
    puts "progress #{idx} of #{total_idx}" if idx % 50 == 0
  end
end

#### main ####
# 特定期間でリクエスタが問い合わせた回数をファイルに書き出す
Dotenv.load

subdomain    = ENV["ZENDESK_SUBDOMAIN"]
mail         = ENV["ZENDESK_MAIL_ADDRESS"]
access_token = ENV["ZENDESK_ACCESS_TOKEN"]

## params
begin_at = "2019-11-01"
end_at   = "2019-12-01"

output_file = "requesters_#{begin_at}_#{end_at}.tsv"

begin_datetime = DateTime.parse(begin_at)
end_datetime = DateTime.parse(end_at)
client = ZendeskClient.new(subdomain, mail, access_token)
tickets = client.fetch_tickets(begin_datetime, end_datetime)

requesters = create_requesters_hash(subdomain, mail, access_token, tickets)

CSV.open(output_file, 'w', :col_sep => "\t") do |f|
  f << ["requester_id", "requester_email", "request_count", "total_request_count", "role"]
  requesters.each do |requester_id, hash|
    arr = []
    arr << requester_id
    arr << hash[:email]
    arr << hash[:count]
    arr << hash[:total_count]
    arr << hash[:role]
    f << arr
  end
end
