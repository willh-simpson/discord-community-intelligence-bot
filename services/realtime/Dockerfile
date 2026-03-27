FROM elixir:1.15

WORKDIR /app

RUN mix local.hex --force
RUN mix local.rebar --force

COPY mix.exs .
COPY mix.lock .

RUN mix deps.get

COPY . .

RUN mix compile

CMD ["mix", "run", "--no-halt"]