# eevoting (倍易投票)

> A decentralized voting system using ethereum blockchain as the only backend service

## development setup

``` bash
# install dependencies
npm install -g truffle@5.0.0-beta.0
npm install -g ganache-cli@6.1.8
npm install

# start ganache-cli
./ganache/start

# compile contracts
truffle compile

# deploy contracts
truffle deploy --reset

# serve with hot reload at 0.0.0.0:8540
npm run dev

# open browser and visit http://yourhost:8540
```

## setup with docker

```
cd docker
docker-compose up -d
docker-compose logs -f --tail 10

# wait until server listening on 8540 port
# open browser and visit http://yourhost:8540
```
