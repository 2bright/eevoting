# eevoting (倍易投票)

> A decentralized voting system using ethereum blockchain as the only backend service

## development setup

``` bash
# install dependencies
npm install
npm install -g ganache-cli
npm install -g truffle@4.1.15

# start ganache-cli
./ganache/start

# compile contracts
truffle compile

# deploy contracts
truffle deploy --reset

# serve with hot reload at 0.0.0.0:8080
npm run dev

# open browser and visit http://yourhost:8080
```

