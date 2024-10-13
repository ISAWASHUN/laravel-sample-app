# ベースイメージとして公式のRubyイメージを使用
FROM ruby:3.2 AS base

# 共通の環境変数を設定
ENV RAILS_ENV=${RAILS_ENV:-development}
ENV APP_HOME /app
WORKDIR $APP_HOME

# 必要なパッケージをインストール
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    yarn \
 && rm -rf /var/lib/apt/lists/*

# GemfileとGemfile.lockをコピー
COPY Gemfile Gemfile.lock ./

# 共通のGemをインストール
RUN bundle install --jobs 4

# アプリケーションコードをコピー
COPY . ./

# --------------------------------------------------
# 開発環境用のビルドステージ
# --------------------------------------------------
FROM base AS development

# ポートの公開
EXPOSE 3000

# ホスト側のコードを優先（docker-composeでボリュームマウントするため）

# エントリーポイント
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

# --------------------------------------------------
# 本番環境用のビルドステージ
# --------------------------------------------------
FROM base AS production

# 本番環境用のGemをインストール（開発・テスト用を除外）
RUN bundle install --without development test --jobs 4

# 不要なファイルを削除してイメージサイズを縮小
RUN rm -rf node_modules tmp/cache

# 資産のプリコンパイル（APIのみの場合は不要）
# RUN bundle exec rails assets:precompile

# ポートの公開
EXPOSE 3000

# エントリーポイント
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
