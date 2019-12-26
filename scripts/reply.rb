require "json"
require "net/http"

require "dotenv"

def update_ticket(subdomain, mail, access_token, ticket_id, ticket)
  url = "https://#{subdomain}.zendesk.com/api/v2/tickets/#{ticket_id}.json"
  uri = URI url
  req = Net::HTTP::Put.new "#{uri.path}?#{uri.query}"
  req.basic_auth "#{mail}/token", access_token
  req['Content-Type'] = 'application/json'
  req.body = ticket
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request req }
end

#### main ####
# 特定チケットにコメントを返信する
Dotenv.load

subdomain    = ENV["ZENDESK_SUBDOMAIN"]
mail         = ENV["ZENDESK_MAIL_ADDRESS"]
access_token = ENV["ZENDESK_ACCESS_TOKEN"]

author_id = 100000
ticket_id = 100
is_public = true
reply_text = <<EOS
ここに返信文を入力する
EOS

ticket_json= {"ticket": {"comment": { "body": reply_text, "public": is_public, "author_id": author_id }}}.to_json

update_ticket(subdomain, mail, access_token, ticket_id, ticket_json)
