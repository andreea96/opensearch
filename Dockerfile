FROM opensearchproject/opensearch:2.13.0

RUN /usr/share/opensearch/bin/opensearch-plugin install --batch ingest-attachment
RUN echo "bootstrap.system_call_filter: false" >> /usr/share/opensearch/config/opensearch.yml
RUN echo "http.cors.enabled: true" >> /usr/share/opensearch/config/opensearch.yml  && \
echo "http.cors.allow-origin: \"*\"" >> /usr/share/opensearch/config/opensearch.yml && \
echo "http.cors.allow-methods: \"OPTIONS, HEAD, GET, POST, PUT, DELETE\"" >> /usr/share/opensearch/config/opensearch.yml && \
echo "http.cors.allow-credentials: true" >> /usr/share/opensearch/config/opensearch.yml && \
echo "http.cors.allow-headers: \"Content-Type, Authorization\"" >> /usr/share/opensearch/config/opensearch.yml

