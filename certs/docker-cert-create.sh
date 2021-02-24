#!/bin/bash
# 
# -------------------------------------------------------------
# 自动创建 Docker TLS 证书
# -------------------------------------------------------------

# 以下是配置信息
# --[BEGIN]------------------------------

# docker服务器ip
IP=`curl icanhazip.com`
# 证书密码
PASSWORD="qaz4399"
# 国家
COUNTRY="CN"
# 州或者省
STATE="HENAN"
# 城市
CITY="XINXIANG"
# 公司名称
ORGANIZATION="SY"
# 公司部门名称 
ORGANIZATIONAL_UNIT="JZYQ"
# 证书所保证的ip或域名
# 此项十分重要，访问地址与此地址不一致证书会被视为无效的
COMMON_NAME="$IP"
# 邮箱
EMAIL="1433343799@qq.com"
# 获取本机公网IP： curl icanhazip.com
# --[END]--

#--------------生成CA根证书-------------------
# 使用rsa算法生成4096位长的私钥
openssl genrsa -aes256 -passout "pass:$PASSWORD" -out "ca-key.pem" 4096
# 使用私钥自签CA根证书
openssl req -new -x509 -days 365 -key "ca-key.pem" -sha256 -out "ca.pem" -passin "pass:$PASSWORD" -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"


#--------------生成服务器证书-------------------
# 生成服务器端的私钥
openssl genrsa -out "server-key.pem" 4096
# 生成服务器端的证书请求
openssl req -subj "/CN=$COMMON_NAME" -sha256 -new -key "server-key.pem" -out server.csr -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/emailAddress=$EMAIL"

# 规定哪些IP或者DNS可以通过证书访问
# IP:$IP,DNS:XXXX
echo "subjectAltName = IP:0.0.0.0,IP:$IP,IP:127.0.0.1" >> extfile.cnf
echo "extendedKeyUsage = serverAuth" >> extfile.cnf
# 使用自定义CA证书签发服务器端的证书请求，生成服务器端证书
# -days 365证书有效期
openssl x509 -req -days 365 -sha256 -in server.csr -passin "pass:$PASSWORD" -CA "ca.pem" -CAkey "ca-key.pem" -CAcreateserial -out "server-cert.pem" -extfile extfile.cnf


#--------------生成客户端证书-------------------
rm -f extfile.cnf
# 生成客户端的私钥
openssl genrsa -out "key.pem" 4096
# 生成客户端的证书请求
openssl req -subj '/CN=client' -new -key "client-key.pem" -out client.csr
echo "extendedKeyUsage = clientAuth" >> extfile.cnf
# 使用自定义CA证书签发客户端的证书请求，生成客户端证书
# -days 365证书有效期
openssl x509 -req -days 365 -sha256 -in client.csr -passin "pass:$PASSWORD" -CA "ca.pem" -CAkey "ca-key.pem" -CAcreateserial -out "cert.pem" -extfile extfile.cnf

rm -vf client.csr server.csr

chmod -v 0400 "ca-key.pem" "key.pem" "server-key.pem"
chmod -v 0444 "ca.pem" "server-cert.pem" "cert.pem"

# 打包客户端证书
mkdir -p "tls-client-certs"
cp -f "ca.pem" "cert.pem" "key.pem" "tls-client-certs/"
cd "tls-client-certs"
tar zcf "tls-client-certs.tar.gz" *
mv "tls-client-certs.tar.gz" ../
cd ..
rm -rf "tls-client-certs"

# 拷贝服务端证书
mkdir -p /etc/docker/certs.d
cp -f "ca.pem" "server-cert.pem" "server-key.pem" /etc/docker/certs.d/

sed -i "s/Execstart=\/usr\/bin\/dockerd.*/Execstart=\/usr\/bin\/dockerd -D --tlsverify=true --tlscert=\/etc\/docker\/certs.d\/server-cert.pem --tlskey=\/etc\/docker\/certs.d\/server-key.pem --tlscacert=\/etc\/docker\/certs.d\/ca.pem -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock/g"

sudo systemctl daemon-reload
sudo service docker restart
#