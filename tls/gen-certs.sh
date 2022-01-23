#!/bin/bash -x

set -e

intermediatecert="mongodb"
rootcert="root-ca"
certs="notify keycloak rabbitmq config-server ccbd-master"
#certs="rabbitmq"

itinerary-api() {
CNHost=booking-data-api-master.default
DNS1=booking-data-api-master
DNS2=booking-data-api-master-tne-ccbd.nce2.paas.amadeus.net
DNS3=localhost
}

mongodb() {
CNHost=mongodb-replicaset.mongodb
DNS1=mongodb-proxy.mongodb
DNS2=localhost
DNS3=mongodb-mongodb.apps.openshift.sofia.ifao.net #mongodb
}

notify() {
CNHost=notify.ccbd
DNS1=notify.ccbd
DNS2=notify
DNS3=localhost
}

rabbitmq() {
CNHost=rabbitmq-rabbitmq-ha.rabbitmq
DNS1=rabbitmq-rabbitmq-ha
DNS2=rabbitmq-rabbitmq-ha.rabbitmq
DNS3=rabbitmq-openshift-rabbitmq.apps.openshift.sofia.ifao.net
}

config-server() {
CNHost=config-server.config
DNS1=config-server.config
DNS2=config-server-tne-ccbd.nce2.paas.amadeus.net
DNS3=localhost
}

keycloak() {
CNHost=keycloak.apps.toc.sofia.ifao.net
DNS1=keycloak-http
DNS2=keycloak-http-tne-ccbd.nce2.paas.amadeus.net
DNS3=localhost
}

ccbd-master() {
CNHost=ccbd-master.ccbd
DNS1=ccbd-master
DNS2=ccbd-master-tne-ccbd.nce2.paas.amadeus.net
DNS3=localhost
}

for C in `echo ${rootcert} ${intermediatecert}-interm`; do

  if [[ -d $C ]]; then
  echo
  echo "Directory $C exist"
  echo
  else
  mkdir $C
  cd $C
  mkdir certs crl newcerts private
  cd ..

  echo 1000 > $C/serial
  touch $C/index.txt $C/index.txt.attr

  echo '
[ ca ]
default_ca = CA_default
[ CA_default ]
dir            = '$C'                     # Where everything is kept
certs          = $dir/certs               # Where the issued certs are kept
crl_dir        = $dir/crl                 # Where the issued crl are kept
database       = $dir/index.txt           # database index file.
new_certs_dir  = $dir/newcerts            # default place for new certs.
certificate    = $dir/certs/ca.ctr          # The CA certificate
serial         = $dir/serial              # The current serial number
crl            = $dir/crl.pem             # The current CRL
private_key    = $dir/private/ca.key  # The private key
RANDFILE       = $dir/.rnd                # private random number file
nameopt        = default_ca
certopt        = default_ca
policy         = policy_match
default_days   = 3650
default_md     = sha256

[ policy_match ]
countryName            = optional
stateOrProvinceName    = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:TRUE

' > $C/openssl.conf
fi
done


generate_root_cert() {

openssl genrsa -out ${rootcert}/private/ca.key 2048
openssl req -config ${rootcert}/openssl.conf -new -x509 -days 3650 -key ${rootcert}/private/ca.key -sha256 \
          -extensions v3_req -out ${rootcert}/certs/ca.crt -subj '/CN=Root-CA'

}


generate_intermediate_cert() {
openssl genrsa -out ${inter}-interm/private/ca.key 2048
openssl req -config ${inter}-interm/openssl.conf -sha256 -new -key ${inter}-interm/private/ca.key \
     -out ${inter}-interm/certs/${inter}.csr -subj "/C=BG/ST=SF/O=iFAO/CN=${CNHost}" \
     -reqexts SAN -config <(cat ${inter}-interm/openssl.conf <(printf "[SAN]\nsubjectAltName=DNS:$DNS1,DNS:$DNS2,DNS:$DNS3"))

openssl ca -batch -config ${rootcert}/openssl.conf -keyfile ${rootcert}/private/ca.key \
     -cert ${rootcert}/certs/ca.crt -extensions v3_req -notext -md sha256  \
     -in ${inter}-interm/certs/${inter}.csr -out ${inter}-interm/certs/${inter}-ca.crt

}


generate_cert() {
 mkdir -p ${cert}
 openssl genrsa -out ${cert}/${cert}.key 2048
 openssl req -new -sha256 -key ${cert}/${cert}.key -subj "/C=BG/ST=SF/O=iFAO/CN=$CNHost" \
       -reqexts SAN -config <(cat ${rootcert}/openssl.conf <(printf "[SAN]\nsubjectAltName=DNS:$DNS1,DNS:$DNS2,DNS:$DNS3"))  \
       -out ${cert}/${cert}.request
 openssl ca -batch -config ${rootcert}/openssl.conf -keyfile ${rootcert}/private/ca.key -cert ${rootcert}/certs/ca.crt \
           -out ${cert}/${cert}.crt -infiles ${cert}/${cert}.request
}



if ! [[ -f ${rootcert}/private/ca.key ]];then
generate_root_cert
fi

for inter in `echo $intermediatecert`;do
     if ! [[ -f ${inter}-interm/private/ca.key ]];then
	 $inter
         generate_intermediate_cert
    fi
done

for cert in `echo $certs`;do
     if ! [[ -f ${cert}/${cert}.key ]];then
	 $cert
         generate_cert
    fi
done
