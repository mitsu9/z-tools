require 'csv'
require 'date'

require "dotenv"

require './lib/client.rb'

def create_requesters_hash(tickets)
  # requester_id -> requester_info のhashを作る
  requesters_hash = tickets.group_by { |t| t['requester_id'] }.each_with_object({}) { |(k, v), hash| hash[k] = { count: v.size } }
  # TODO: requesterについて必要な情報を取得する
end

#### main ####
# 特定期間でリクエスタが問い合わせた回数をファイルに書き出す
Dotenv.load

subdomain    = ENV["ZENDESK_SUBDOMAIN"]
mail         = ENV["ZENDESK_MAIL_ADDRESS"]
access_token = ENV["ZENDESK_ACCESS_TOKEN"]
output_file = "requesters_#{begin_at}_#{end_at}.tsv"

## params
begin_at = "2019-11-01"
end_at   = "2019-12-01"

begin_datetime = DateTime.parse(begin_at)
end_datetime = DateTime.parse(end_at)
client = ZendeskClient.new(subdomain, mail, access_token)
tickets = client.fetch_tickets(begin_datetime, end_datetime)

requesters = create_requesters_hash(tickets)

CSV.open(output_file, 'w', :col_sep => "\t") do |f|
  f << ["requester_id", "request_count"]
  requesters.each do |requester_id, hash|
    arr = []
    arr << requester_id
    arr << hash[:count]
    f << arr
  end
end
