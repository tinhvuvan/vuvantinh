FROM 10.60.129.132:8890/elasticsearch:8.10.2
USER root
RUN usermod -u 1001 elasticsearch
RUN chmod -R 777 /usr/share/elasticsearch
#Setup time
ENV TZ=Asia/Ho_Chi_Minh
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN usermod -u 1001 elasticsearch
USER elasticsearch
