FROM mcr.microsoft.com/playwright:v1.50.0-noble

RUN apt update
RUN apt install -y bind9
RUN apt install -y bind9-host
RUN npx playwright install
