# forge-fhevm
A forge library to run Zama's fhevm 

## Dependencies

#### package.json

```json
"dependencies": {
    "fhevm-core-contracts": "^0.6.0",
    "@openzeppelin/contracts": "^5.1.0",
    "@openzeppelin/contracts-upgradeable": "^5.1.0",
}
```

## foundry.toml 

```toml
[profile.default]
solc = "0.8.24"
evm_version = "cancun"
src = "src"
out = "out"
test = "test"
cache_path = "cache"
fs_permissions = [{ access = "read", path = "./node_modules/fhevm-core-contracts/artifacts"}, { access = "read", path = "./out"}]
libs = ["dependencies", "node-modules"]
remappings= [
    "forge-std/=dependencies/forge-std-1.9.3/",
    "forge-fhevm/=dependencies/forge-fhevm-0.6.0/",
    "forge-fhevm-config/=dependencies/forge-fhevm-0.6.0/configs/default/",
    "fhevm/=dependencies/forge-fhevm-0.6.0/src/libs/fhevm-debug/"
]

[dependencies]
forge-std = "1.9.3"
forge-fhevm = { version = "0.6.0", git = "https://github.com/0xalexbel/forge-fhevm.git" }

[soldeer]
remappings_version = false
remappings_generate = false
remappings_regenerate = false
remappings_prefix = ""
remappings_location = "config"
```

## Development

```bash
# restore foundry.toml
cp ./foundry.toml.dev ./foundry.toml

# restore remappings.txt (for vscode)
cp ./remappings.txt.debug ./remappings.txt

# install dependencies
forge soldeer install

# install dependencies (fhevm-core-contracts + openzeppelin)
npm install

# run tests
forge test
```

## Tests

Tests are failing in the following situations:

```bash
# Transient storage is cleared between two consecutive calls therefore ACL permissions are always reset.
forge test --isolate
```

```bash
# Transient storage is cleared between two consecutive calls therefore ACL permissions are always reset.
forge test --gas-report
```

See https://github.com/foundry-rs/foundry/issues/7499#issuecomment-2021163562 for more information.

