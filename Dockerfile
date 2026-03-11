FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl

WORKDIR /app

COPY app.sh .

RUN chmod +x app.sh

CMD ["./app.sh"]