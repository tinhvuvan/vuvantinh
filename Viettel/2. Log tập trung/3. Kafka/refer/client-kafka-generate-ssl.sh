#!/bin/bash

set -e

KEYSTORE_CLIENT_FILENAME="kafka.client.keystore.jks"
VALIDITY_IN_DAYS=3650
TRUSTSTORE_CLIENT_FILENAME="kafka.client.truststore.jks"
TRUSTSTORE_WORKING_DIRECTORY="truststore"
CLIENT_WORKING_DIRECTORY="client_certificates"
CLIENT_SIGN_REQUEST="client-request"
CLIENT_SIGN_REQUEST_SRL="ca-cert.srl"
CLIENT_P12="client.pkcs12"
CLIENT_KEY_PEM="client_key.pem"
KEYSTORE_SIGNED_CERT="client-cert.pem"
CA_CERT_PEM="CA_cert.pem"
CA_CERT_FILE=""
CA_KEY_FILE=""

COUNTRY="VN"
STATE="HN"
OU="VTNET"
O="VIETTEL"
CN="LOGTT"
LOCATION="HN"
PASS="123123"

###Check file and folder exists
function file_exists_and_exit() {
  echo -e "\e[1;31m '$1' cannot exist. Move or delete it before \e[0m"
  echo -e "\e[1;31m Re-running this script. \e[0m"
  exit 1
}


if [ -e "$CLIENT_WORKING_DIRECTORY" ]; then
  file_exists_and_exit $CLIENT_WORKING_DIRECTORY
fi

if [ -e "$CLIENT_P12" ]; then
  file_exists_and_exit $CLIENT_P12
fi

if [ -e "$KEYSTORE_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST_SRL
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi

##Welcome
echo 
echo -e  "\e[1;34m Welcome to the Fluentd SSL certificates generator script.\e[0m"

echo -e
echo -e "\e[1;34m First, you need to check if there is a ca-cert and ca-key file \e[0m"
echo -e "\e[1;34m created by the Kafka-generate-ssl.sh script? \e[0m"
echo 
echo -n -e "\e[1;36m Do you have ca-cert file and ca-key file? [y/n] \e[0m"
read check_ca_cert_ca_key


if [ "$check_ca_cert_ca_key" == "y" ]; then
###
  mkdir $CLIENT_WORKING_DIRECTORY
  echo -e
  echo -n -e "\e[1;36m Enter the path of the ca-cert file, e.g., /home/ca-cert: \e[0m"
  read -e CA_CERT_FILE

  if ! [ -f $CA_CERT_FILE ]; then
    echo -e "\e[1;31m $CA_CERT_FILE isn't a file. Exiting.\e[0m"
    exit 1
  fi

  echo -e -n "\e[1;36m  Enter the path of the ca-key file, e.g., /home/ca-key: \e[0m"
  read -e CA_KEY_FILE

  if ! [ -f $CA_KEY_FILE ]; then
    echo -e "\e[1;31m  $CA_KEY_FILE isn't a file. Exiting.\e[0m"
    exit 1
  fi
  
  echo -e "\e[1;33mOK, we'll generate a trust store and key store.\e[0m"
  echo 
  echo -e "\e[1;35m Step 1: Generate the trust store. \e[0m"
  echo 

### STEP 1
  keytool -keystore $CLIENT_WORKING_DIRECTORY/$TRUSTSTORE_CLIENT_FILENAME \
    -alias CARoot -importcert -file $CA_CERT_FILE -noprompt -storepass $PASS
  
  echo -e "\e[1;32m Successfully! \e[0m"
  echo 
  echo -e "\e[1;35m Step 2: Generate the key store.\e[0m"
  echo 

  keytool -keystore $CLIENT_WORKING_DIRECTORY/$KEYSTORE_CLIENT_FILENAME -alias localhost \
    -validity $VALIDITY_IN_DAYS -genkey -keyalg RSA \
    -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$O, OU=$OU, CN=$CN" -keypass $PASS -storepass $PASS
  
### STEP 2
  keytool -keystore $CLIENT_WORKING_DIRECTORY/$KEYSTORE_CLIENT_FILENAME -alias CARoot -import -file $CA_CERT_FILE \
    -keypass $PASS -storepass $PASS -noprompt
  echo -e "\e[1;32m Successfully! \e[0m"
#### STEP 3
  echo 
  echo -e "\e[1;35m Step 3: Now a certificate signing request will be made to the keystore. \e[0m"
  echo 
  keytool -keystore $CLIENT_WORKING_DIRECTORY/$KEYSTORE_CLIENT_FILENAME -alias localhost \
    -certreq -file $CLIENT_WORKING_DIRECTORY/$CLIENT_SIGN_REQUEST -storepass $PASS -noprompt
  
  echo -e "\e[1;32m Successfully! \e[0m"
### STEP 4  
  echo 
  echo -e "\e[1;35m Step 4: Now the trust store's private key (CA) will sign the keystore's certificate. \e[0m"
  echo 
  openssl x509 -req -CA $CA_CERT_FILE -CAkey $CA_KEY_FILE -in $CLIENT_WORKING_DIRECTORY/$CLIENT_SIGN_REQUEST \
    -out $CLIENT_WORKING_DIRECTORY/$KEYSTORE_SIGNED_CERT -days $VALIDITY_IN_DAYS -CAcreateserial
  
  echo -e "\e[1;32m Successfully! \e[0m"
### STEP 5
  echo 
  echo -e "\e[1;35m Step 5: Now create the client key .pkcs12 file. \e[0m"
  echo 
  keytool -v -importkeystore -srckeystore $CLIENT_WORKING_DIRECTORY/$KEYSTORE_CLIENT_FILENAME -srcalias localhost \
    -destkeystore $CLIENT_WORKING_DIRECTORY/$CLIENT_P12 -deststoretype PKCS12 -noprompt -deststorepass \
	$PASS -srcstorepass $PASS
  echo
  echo -e "\e[1;32m Successfully! \e[0m"
  echo
  echo -e "\e[1;35m Step 6: Now create the client key .pem file \e[0m"
  openssl pkcs12 -in $CLIENT_WORKING_DIRECTORY/$CLIENT_P12 -nocerts -nodes -out $CLIENT_WORKING_DIRECTORY/$CLIENT_KEY_PEM -passout pass:$PASS -passin pass:$PASS
  
  echo -e "\e[1;32m Successfully! \e[0m"
### STEP 6
  echo
  echo -e "\e[1;35m Step 7: Now export CA cert .pem file. \e[0m"
  keytool -exportcert -alias CARoot -keystore $CLIENT_WORKING_DIRECTORY/$KEYSTORE_CLIENT_FILENAME \
    -rfc -file $CLIENT_WORKING_DIRECTORY/$CA_CERT_PEM -storepass $PASS
  echo 
  echo -e "\e[1;32m Successfully! \e[0m"
  echo
  echo -e "\e[1;33m Three files were created in $CLIENT_WORKING_DIRECTORY/ folder: \e[0m"
  echo -e "\e[1;33m  - $CLIENT_WORKING_DIRECTORY/$KEYSTORE_SIGNED_CERT \e[0m"
  echo -e "\e[1;33m  - $CLIENT_WORKING_DIRECTORY/$CLIENT_KEY_PEM \e[0m"
  echo -e "\e[1;33m  - $CLIENT_WORKING_DIRECTORY/$CA_CERT_PEM \e[0m"
  echo 
  echo -e "\e[1;32m All done! \e[0m"
  echo -e
  echo -e "\e[1;31m Delete intermediate files? They are: \e[0m"
  echo -e "\e[1;31m - '$CLIENT_WORKING_DIRECTORY/$KEYSTORE_CLIENT_FILENAME'"
  echo -e "\e[1;31m - '$CLIENT_WORKING_DIRECTORY/$TRUSTSTORE_CLIENT_FILENAME' \e[0m"
  echo -e "\e[1;31m - '$CLIENT_WORKING_DIRECTORY/$CLIENT_SIGN_REQUEST' \e[0m"
  echo -e "\e[1;31m - '$CLIENT_SIGN_REQUEST_SRL' \e[0m"
  
  echo -e -n "\e[1;36m Delete (Recommend delete)? [y/n] \e[0m"
  read delete_intermediate_files
  if [ "$delete_intermediate_files" == "y" ]; then
    rm $CLIENT_WORKING_DIRECTORY/$KEYSTORE_CLIENT_FILENAME
    rm $CLIENT_WORKING_DIRECTORY/$TRUSTSTORE_CLIENT_FILENAME
    rm $CLIENT_WORKING_DIRECTORY/$CLIENT_SIGN_REQUEST
    rm $CLIENT_SIGN_REQUEST_SRL
  fi

else
  echo 
  echo -e -n "\e[1;31m You must run the kafka-generate-ssl.sh script first to generate the ca-cert and ca-key files. \e[0m"
  exit 1
fi

