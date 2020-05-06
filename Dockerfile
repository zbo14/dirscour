FROM caffix/amass

COPY . /dirscour

WORKDIR /dirscour

RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash bind-tools git python3 && \
    git clone https://github.com/maurosoria/dirsearch.git

ENTRYPOINT bash dirscour.sh \
  -d /dirscour/dirsearch \
  -o /dirscour/output \
  -p "$nprocs" \
  "$target"
