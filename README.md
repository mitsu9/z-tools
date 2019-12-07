# z-tools
Tools for Zendesk

## 環境構築
```
$ bundle install
$ touch .env
$ ZENDESK_SUBDOMAIN="" >> .env
$ ZENDESK_MAIL_ADDRESS="" >> .env
$ ZENDESK_ACCESS_TOKEN="" >> .env
```

## ビュー一覧
アクティブかつ個人ビューを除いたビューを`active_views.tsv`に書き出す.
```
$ bundle exec ruby scripts/views.rb
```
