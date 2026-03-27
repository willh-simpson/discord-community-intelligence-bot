FROM python:3.11-slim

WORKDIR /app
COPY . .

RUN pip install -U pip
RUN pip install discord.py requests redis

CMD ["python", "bot.py"]