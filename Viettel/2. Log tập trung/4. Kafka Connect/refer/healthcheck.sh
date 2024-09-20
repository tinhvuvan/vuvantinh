#!/usr/bin/env bash

if [[ -n $CONNECT_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM ]]; then
  if [[ $(curl -s -o /dev/null -w %{http_code} http://$CONNECT_REST_ADVERTISED_HOST_NAME:$CONNECT_REST_PORT/connectors) = 200 ]]; then
    echo "Woohoo! Kafka Connect is up!"
    exit 0
  else 
    echo -e $(date) "\tKafka Connect HTTP state: " $(curl -s -o /dev/null -w %{http_code} $CONNECT_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM://$CONNECT_REST_ADVERTISED_HOST_NAME:$CONNECT_REST_PORT/connectors) " (waiting for 200)"
    exit 1
  fi
else
  if [[ $(curl -k --cert /etc/kafka-connect/secrets/client-cert.pem  --key /etc/kafka-connect/secrets/client-key.pem --cacert /etc/kafka-connect/secrets/CA_cert.pem -s -o /dev/null -w %{http_code} https://$CONNECT_REST_ADVERTISED_HOST_NAME:$CONNECT_SECURE_REST_PORT/connectors) = 200 ]]; then
    echo "Woohoo! Kafka Connect with SSL listener is up!"
    exit 0
  else 
    echo -e $(date) "\tKafka Connect with SSL listener HTTP state: " $(curl -k --cert /etc/kafka-connect/secrets/client-cert.pem  --key /etc/kafka-connect/secrets/client-key.pem --cacert /etc/kafka-connect/secrets/CA_cert.pem -s -o /dev/null -w %{http_code} https://$CONNECT_REST_ADVERTISED_HOST_NAME:$CONNECT_SECURE_REST_PORT/connectors) " (waiting for 200)"
    exit 1
  fi
fi
