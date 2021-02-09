#!/bin/bash
# 
# -------------------------------------------------------------
# 自动创建 Docker TLS 证书
# -------------------------------------------------------------

# 以下是配置信息
# --[BEGIN]------------------------------

CODE="dp"
# docker服务器ip
IP="docker服务器ip"
# 证书密码
PASSWORD="证书密码"
# 国家
COUNTRY="CN"
# 州或者省
STATE="BEIJING"
# 城市
CITY="BEIJING"
# 公司名称
ORGANIZATION="公司"
# 公司部门名称 
ORGANIZATIONAL_UNIT="Dev"
# 证书所保证的ip或域名
# 此项十分重要，访问地址与此地址不一致证书会被视为无效的
COMMON_NAME="$IP"
# 邮箱
EMAIL="邮箱"
# 获取本机公网IP： curl icanhazip.com
# --[END]--

#--------------生成CA根证书-------------------
# 使用rsa算法生成4096位长的私钥
openssl genrsa -aes256 -passout "pass:$PASSWORD" -out "ca-key-$CODE.pem" 4096
# 使用私钥自签CA根证书
openssl req -new -x509 -days 365 -key "ca-key-$CODE.pem" -sha256 -out "ca-$CODE.pem" -passin "pass:$PASSWORD" -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"


#--------------生成服务器证书-------------------
# 生成服务器端的私钥
openssl genrsa -out "server-key-$CODE.pem" 4096
# 生成服务器端的证书请求
openssl req -subj "/CN=$COMMON_NAME" -sha256 -new -key "server-key-$CODE.pem" -out server.csr

# 规定哪些IP或者DNS可以通过证书访问
# IP:$IP,DNS:XXXX
echo "subjectAltName = IP:$IP,IP:127.0.0.1" >> extfile.cnf
echo "extendedKeyUsage = serverAuth" >> extfile.cnf
# 使用自定义CA证书签发服务器端的证书请求，生成服务器端证书
# -days 365证书有效期
openssl x509 -req -days 365 -sha256 -in server.csr -passin "pass:$PASSWORD" -CA "ca-$CODE.pem" -CAkey "ca-key-$CODE.pem" -CAcreateserial -out "server-cert-$CODE.pem" -extfile extfile.cnf


#--------------生成客户端证书-------------------
rm -f extfile.cnf
# 生成客户端的私钥
openssl genrsa -out "key-$CODE.pem" 4096
# 生成客户端的证书请求
openssl req -subj '/CN=client' -new -key "key-$CODE.pem" -out client.csr
echo "extendedKeyUsage = clientAuth" >> extfile.cnf
# 使用自定义CA证书签发客户端的证书请求，生成客户端证书
# -days 365证书有效期
openssl x509 -req -days 365 -sha256 -in client.csr -passin "pass:$PASSWORD" -CA "ca-$CODE.pem" -CAkey "ca-key-$CODE.pem" -CAcreateserial -out "cert-$CODE.pem" -extfile extfile.cnf

rm -vf client.csr server.csr

chmod -v 0400 "ca-key-$CODE.pem" "key-$CODE.pem" "server-key-$CODE.pem"
chmod -v 0444 "ca-$CODE.pem" "server-cert-$CODE.pem" "cert-$CODE.pem"

# 打包客户端证书
mkdir -p "tls-client-certs-$CODE"
cp -f "ca-$CODE.pem" "cert-$CODE.pem" "key-$CODE.pem" "tls-client-certs-$CODE/"
cd "tls-client-certs-$CODE"
tar zcf "tls-client-certs-$CODE.tar.gz" *
mv "tls-client-certs-$CODE.tar.gz" ../
cd ..
rm -rf "tls-client-certs-$CODE"

# 拷贝服务端证书
mkdir -p /etc/docker/certs.d
cp "ca-$CODE.pem" "server-cert-$CODE.pem" "server-key-$CODE.pem" /etc/docker/certs.d/