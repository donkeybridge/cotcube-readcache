curl -sH 'Accept-Encoding: gzip, deflate' 100.100.0.14:8081/${1:-keys} | pigz -d | head -c ${2:-250}; echo

