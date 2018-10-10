// Allows us to use ES6 in our migrations and tests.

module.exports = {
  contracts_build_directory: "./dist/contracts",
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
      gas: 8000000
    }
  }
}
