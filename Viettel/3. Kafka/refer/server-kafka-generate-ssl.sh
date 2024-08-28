#!/usr/bin/env bash

set -eu

KEYSTORE_FILENAME="kafka.server.keystore.jks"
VALIDITY_IN_DAYS=3650
TRUSTSTORE_FILENAME="kafka.server.truststore.jks"
SERVER_WORKING_DIRECTORY="kafka_server_cert"
CA_CERT_FILE="ca-cert"
CA_KEY_FILE="ca-key"
KEYSTORE_SIGN_REQUEST="cert-file"
KEYSTORE_SIGN_REQUEST_SRL="ca-cert.srl"
KEYSTORE_SIGNED_CERT="cert-signed"

COUNTRY="VN"
STATE="HN"
OU="VTNET"
O="VIETTEL"
CN="LOGTT"
LOCATION="HN"
PASS="123123"


function file_exists_and_exit() {
  echo -e -e "\e[1;31m '$1' cannot exist. Move or delete it before \e[0m"
  echo -e -e "\e[1;31m Re-running this script. \e[0m"
  exit 1
}

if [ -e "$SERVER_WORKING_DIRECTORY" ]; then
  file_exists_and_exit $SERVER_WORKING_DIRECTORY
fi

if [ -e "$CA_CERT_FILE" ]; then
  file_exists_and_exit $CA_CERT_FILE
fi

if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi

if [ -e "$KEYSTORE_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST_SRL
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi




echo -e "\e[1;34m Welcome to the Kafka SSL keystore and trust store generator script. \e[0m"

echo -e
echo -e "\e[1;34m First, do you need to generate a trust store and associated private key, \e[0m"
echo -e "\e[1;34m or do you already have a trust store file and private key? \e[0m"
echo -e
echo -e -n "\e[1;36m Do you need to generate a trust store and associated private key? [y/n] \e[0m"
read generate_trust_store

trust_store_file=""
trust_store_private_key_file=""

if [ "$generate_trust_store" == "y" ]; then
  if [ -e "$SERVER_WORKING_DIRECTORY" ]; then
    file_exists_and_exit $SERVER_WORKING_DIRECTORY
  fi

  mkdir $SERVER_WORKING_DIRECTORY
  echo -e
  echo -e "\e[1;33m OK, we'll generate a trust store and associated private key. \e[0m"
  echo -e
  echo -e "\e[1;35m Step 1: Generate the private key. \e[0m"
  echo -e

  openssl req -new -x509 -keyout $CA_KEY_FILE \
    -out $CA_CERT_FILE -days $VALIDITY_IN_DAYS -nodes \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$O/OU=$OU/CN=$CN"

  trust_store_private_key_file="ca-key"
  echo -e
  echo -e "\e[1;32m Successfully! \e[0m"
  echo -e
  echo -e "\e[1;34m Two files were created: \e[0m"
  echo -e "\e[1;34m  - $CA_KEY_FILE -- the private key used later to sign certificates \e[0m"
  echo -e "\e[1;34m  - $CA_CERT_FILE -- the certificate that will be"
  echo -e "\e[1;34m    stored in the trust store in a moment and serve as the certificate \e[0m"
  echo -e "\e[1;34m   authority (CA). Once this certificate has been stored in the trust \e[0m"
  echo -e "\e[1;34m    store, it will be deleted. It can be retrieved from the trust store via: \e[0m"
  echo -e "\e[1;34m    $ keytool -keystore <trust-store-file> -export -alias CARoot -rfc \e[0m"

  echo -e
  echo -e "\e[1;35m Step 2: Now the trust store will be generated from the certificate. \e[0m"
  echo -e

  keytool -keystore $SERVER_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME \
    -alias CARoot -import -file $CA_CERT_FILE \
    -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" -keypass $PASS -storepass $PASS

  trust_store_file="$SERVER_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME"
  echo -e "\e[1;32m Successfully! \e[0m"
  echo -e
  echo -e "\e[1;33m $SERVER_WORKING_DIRECTORY/$TRUSTSTORE_FILENAME was created. \e[0m"

else
  echo -e
  echo -e -n "\e[1;36m Enter the path of the trust store file, e.g, /home/kafka.server.truststore.jks \e[0m"
  read -e trust_store_file

  if ! [ -f $trust_store_file ]; then
    echo -e "\e[1;31m $trust_store_file isn't a file. Exiting.\e[0m"
    exit 1
  fi

  echo -e -n "\e[1;36m Enter the path of the trust store's private key, e.g, /home/ca-key \e[0m"
  read -e trust_store_private_key_file

  if ! [ -f $trust_store_private_key_file ]; then
    echo -e "\e[1;31m $trust_store_private_key_file isn't a file. Exiting.\e[0m"
    exit 1
  fi
fi

echo -e
echo -e "\e[1;35m Continuing with: \e[0m"
echo -e "\e[1;35m  - trust store file:        $trust_store_file \e[0m"
echo -e "\e[1;35m  - trust store private key: $trust_store_private_key_file \e[0m"

if [[ ! -e $SERVER_WORKING_DIRECTORY ]]; then
  mkdir $SERVER_WORKING_DIRECTORY
fi

echo -e
echo -e "\e[1;34m STEP 3: Now, a keystore will be generated. Each broker and logical client needs its own keystore. \e[0m"
echo -e "\e[1;34m This script will create only one keystore. Run this script multiple times for multiple keystores. \e[0m"
echo -e
echo -e "\e[1;31m NOTE: currently in Kafka, the Common Name (CN) does not need to be the FQDN of \e[0m"
echo -e "\e[1;31m      this host. However, at some point, this may change. As such, make the CN \e[0m"
echo -e "\e[1;31m      the FQDN. Some operating systems call the CN prompt 'first / last name' \e[0m"

echo -e "\e[1;34m To learn more about CNs and FQDNs, read: \e[0m"
echo -e "\e[1;34m https://docs.oracle.com/javase/7/docs/api/javax/net/ssl/X509ExtendedTrustManager.html \e[0m"

keytool -keystore $SERVER_WORKING_DIRECTORY/$KEYSTORE_FILENAME \
  -alias localhost -validity $VALIDITY_IN_DAYS -genkey -keyalg RSA \
   -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" -keypass $PASS -storepass $PASS
echo -e
echo -e "\e[1;32m Successfully! \e[0m"
echo -e
echo -e "\e[1;34m '$SERVER_WORKING_DIRECTORY/$KEYSTORE_FILENAME' now contains a key pair and a \e[0m"
echo -e "\e[1;34m self-signed certificate. Again, this keystore can only be used for one broker or \e[0m"
echo -e "\e[1;34m one logical client. Other brokers or clients need to generate their own keystores. \e[0m"

echo -e
echo -e "\e[1;34m STEP 4: Fetching the certificate from the trust store and storing in $CA_CERT_FILE. \e[0m"
echo -e
keytool -keystore $trust_store_file -export -alias CARoot -rfc -file $CA_CERT_FILE -keypass $PASS -storepass $PASS
echo -e
echo -e "\e[1;32m Successfully! \e[0m"
echo -e
echo -e "\e[1;35m step 5: Now a certificate signing request will be made to the keystore. \e[0m"
echo -e
keytool -keystore $SERVER_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias localhost \
  -certreq -file $KEYSTORE_SIGN_REQUEST -keypass $PASS -storepass $PASS
echo -e
echo -e "\e[1;32m Successfully! \e[0m"
echo -e
echo -e "\e[1;35m step 6: Now the trust store's private key (CA) will sign the keystore's certificate. \e[0m"
echo -e
openssl x509 -req -CA $CA_CERT_FILE -CAkey $trust_store_private_key_file \
  -in $KEYSTORE_SIGN_REQUEST -out $KEYSTORE_SIGNED_CERT \
  -days $VALIDITY_IN_DAYS -CAcreateserial
# creates $KEYSTORE_SIGN_REQUEST_SRL which is never used or needed.
echo -e
echo -e "\e[1;32m Successfully! \e[0m"
echo -e
echo -e "\e[1;35m STEP 7: Now the CA will be imported into the keystore. \e[0m"
echo -e
keytool -keystore $SERVER_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias CARoot \
  -import -file $CA_CERT_FILE -keypass $PASS -storepass $PASS -noprompt
echo -e
echo -e "\e[1;32m Successfully! \e[0m"

echo -e
echo -e "\e[1;35m STEP 8: Now the keystore's signed certificate will be imported back into the keystore. \e[0m"
echo -e
keytool -keystore $SERVER_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias localhost -import \
  -file $KEYSTORE_SIGNED_CERT -noprompt -keypass $PASS -storepass $PASS
echo -e
echo -e "\e[1;32m Successfully! \e[0m"
#create kafka keystore password and kafka truststore password file
echo -e $PASS > $SERVER_WORKING_DIRECTORY/.kafka_keystore_password
echo -e $PASS > $SERVER_WORKING_DIRECTORY/.kafka_truststore_password

echo -e
echo -e "\e[1;31m Delete intermediate files? They are: \e[0m"
echo -e "\e[1;31m  - '$KEYSTORE_SIGN_REQUEST_SRL': CA serial number \e[0m"
echo -e "\e[1;31m  - '$KEYSTORE_SIGN_REQUEST': the keystore's certificate signing request \e[0m"
echo -e "\e[1;31m  - '$KEYSTORE_SIGNED_CERT': the keystore's certificate, signed by the CA, and stored back into the keystore \e[0m"
echo -e -n "\e[1;36m Delete (Recommend delete)? [y/n] \e[0m"
read delete_intermediate_files
if [ "$delete_intermediate_files" == "y" ]; then
  rm $KEYSTORE_SIGN_REQUEST_SRL
  rm $KEYSTORE_SIGN_REQUEST
  rm $KEYSTORE_SIGNED_CERT
fi
echo -e
echo -e "\e[1;33mAll done! \e[0m"
echo -e
echo -e "\e[1;33mUsing $KEYSTORE_FILENAME, $TRUSTSTORE_FILENAME, .kafka_keystore_password \e[0m"
echo -e "\e[1;33mand .kafka_truststore_password file in $SERVER_WORKING_DIRECTORY folder to configure Kafka SSL \e[0m"