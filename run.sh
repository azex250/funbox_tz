
export SECRET_KEY_BASE=`mix phx.gen.secret`
mix deps.get --only prod
MIX_ENV=prod mix compile

npm run deploy --prefix ./assets
mix phx.digest

PORT=8080 MIX_ENV=prod mix phx.server
