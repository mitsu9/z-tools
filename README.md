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

## リクエスタ情報一覧
特定期間に問い合わせをしたリクエスタの一覧を`requesters_<begin_at>_<end_at>.tsv`に書き出す.
```
$ bundle exec ruby scripts/requesters.rb
```
