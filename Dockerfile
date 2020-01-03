FROM elixir

COPY . /app

RUN yes | mix local.hex
RUN yes | mix archive.install hex phx_new 1.4.11
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt install nodejs --yes
RUN apt install npm --yes
ENTRYPOINT cd /app && ./run.sh
