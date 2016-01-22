FROM alpine:3.2

RUN apk add --update bash && rm -rf /var/cache/apk/*

ADD bin/test_lock.sh /tmp/dfs/test_lock.sh
RUN chmod 755 /tmp/dfs/test_lock.sh

CMD ["/tmp/dfs/test_lock.sh"]