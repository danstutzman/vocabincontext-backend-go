#!/bin/bash -ex
cd $GOPATH/src/github.com/danielstutzman/vocabincontext-backend-go

go install
go vet .

fwknop -s -n vocabincontext.danstutzman.com
ssh root@vocabincontext.danstutzman.com <<"EOF"
  set -ex

  id -u vocabincontext-backend-go &>/dev/null || sudo useradd vocabincontext-backend-go
  sudo mkdir -p /home/vocabincontext-backend-go
  sudo chown vocabincontext-backend-go:vocabincontext-backend-go /home/vocabincontext-backend-go
  cd /home/vocabincontext-backend-go

  if [ `uname -p` == i686 ];     then ARCH=386
  elif [ `uname -p` == x86_64 ]; then ARCH=amd64; fi

  GOROOT=/home/vocabincontext-backend-go/go1.7.3.linux-$ARCH
  if [ ! -e $GOROOT ]; then
    sudo curl https://storage.googleapis.com/golang/go1.7.3.linux-$ARCH.tar.gz >go1.7.3.linux-$ARCH.tar.gz
    chown vocabincontext-backend-go:vocabincontext-backend-go go1.7.3.linux-$ARCH.tar.gz
    sudo -u vocabincontext-backend-go tar xzf go1.7.3.linux-$ARCH.tar.gz
    sudo -u vocabincontext-backend-go mv go $GOROOT
  fi
  GOPATH=/home/vocabincontext-backend-go/gopath
  sudo -u vocabincontext-backend-go mkdir -p $GOPATH
  sudo -u vocabincontext-backend-go mkdir -p $GOPATH/src/github.com/danielstutzman/vocabincontext-backend-go
EOF
time rsync -a -e "ssh -C" -r . root@vocabincontext.danstutzman.com:/home/vocabincontext-backend-go/gopath/src/github.com/danielstutzman/vocabincontext-backend-go --include='*.go' --include='*/' --exclude='*' --prune-empty-dirs
ssh root@vocabincontext.danstutzman.com <<"EOF"
  set -ex

  if [ `uname -p` == i686 ];     then ARCH=386
  elif [ `uname -p` == x86_64 ]; then ARCH=amd64; fi

  GOROOT=/home/vocabincontext-backend-go/go1.7.3.linux-$ARCH
  GOPATH=/home/vocabincontext-backend-go/gopath
  cd $GOPATH/src/github.com/danielstutzman/vocabincontext-backend-go
  chown -R vocabincontext-backend-go:vocabincontext-backend-go .
  time sudo -u vocabincontext-backend-go GOPATH=$GOPATH GOROOT=$GOROOT $GOROOT/bin/go install

  tee /etc/init/vocabincontext-backend-go.conf <<EOF2
    chdir /home/vocabincontext-backend-go
    start on started remote_syslog
    setuid vocabincontext-backend-go
    setgid vocabincontext-backend-go
    respawn
    respawn limit 2 60
    script
      /home/vocabincontext-backend-go/vocabincontext-backend-go --port 8081 --postgres_credentials_path /etc/vocabincontext_postgres_credentials.json
    end script
EOF2

  sudo service vocabincontext-backend-go stop || true
  sudo -u vocabincontext-backend-go cp -rv $GOPATH/bin/vocabincontext-backend-go \
    /home/vocabincontext-backend-go
  sudo service vocabincontext-backend-go start
  sleep 1
  curl -f http://localhost:8081/api/excerpt_list.json >/dev/null

  sudo ufw allow 8081
EOF
