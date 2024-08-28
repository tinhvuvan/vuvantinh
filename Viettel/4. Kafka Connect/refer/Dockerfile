FROM 10.60.129.132:8890/confluentinc/cp-kafka-connect:7.4.3-1-ubi8
USER root

#Setup time
ENV TZ=Asia/Ho_Chi_Minh
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
#Setup JMX exporter
COPY ./jmx_prometheus_javaagent-0.20.0.jar /etc/confluent/docker/
COPY ./kafka-connect.yml /etc/confluent/docker/
COPY ./connect-distributed /bin/
COPY ./confluentinc-kafka-connect-elasticsearch-14.0.11 /usr/share/java/confluentinc-kafka-connect-elasticsearch-14.0.11
COPY ./healthcheck.sh /etc/confluent/docker/
##Set permission
RUN useradd kafka_connect
RUN chmod -R 777 /var/lib/
RUN chmod -R 777 /etc/kafka-connect/
RUN chmod -R 777 /etc/kafka/
RUN chmod -R 777 /usr/share/java/confluentinc-kafka-connect-elasticsearch-14.0.11
RUN chmod 777 /usr/bin/connect-distributed
RUN chmod 777 /etc/confluent/docker/jmx_prometheus_javaagent-0.20.0.jar
RUN chmod 777 /etc/confluent/docker/kafka-connect.yml
RUN usermod -u 1001 kafka_connect
USER kafka_connect
WORKDIR /home/kafka_connect
#
